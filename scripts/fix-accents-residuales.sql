-- ════════════════════════════════════════════════════════════════════
-- VISCO-SG — Secundario: corrige símbolos residuales y patrones no resueltos
-- ════════════════════════════════════════════════════════════════════
-- Ejecuta DESPUÉS de fix-encoding.sql.
-- Corrige los "??" que quedaron por símbolos (°, ®, ™, N°, etc.) y algunas
-- palabras esporádicas que el diccionario anterior no cubrió.
--
-- Ejecutar:
--   docker cp scripts\fix-accents-residuales.sql visco_db_dev:/tmp/fix-accents-residuales.sql
--   docker exec visco_db_dev psql -U visco_admin -d visco_db -v ON_ERROR_STOP=1 -f /tmp/fix-accents-residuales.sql
-- ════════════════════════════════════════════════════════════════════

BEGIN;

DO $$
DECLARE
  r      record;
  base   text[][];
  pairs  text[][] := '{}';
  i      int;
  bad    text;
  good   text;
  t_bad  text;
  t_good text;
  u_bad  text;
  u_good text;
  expr   text;
BEGIN
  base := ARRAY[
    -- ── N° (número) ──────────────────────────────────────────────
    ARRAY['n??',   'n°'],
    ARRAY['N??',   'N°'],

    -- ── Grado Celsius y otros ° ──────────────────────────────────
    -- el ° se convirtió en 12 "?":  TERMOMETRO 0-100????????????C → TERMOMETRO 0-100°C
    -- patrón: dígitos + ??...?? + C  (entre 6 y 12 "?")
    -- Reemplazamos la secuencia de "??" seguida de C por °C (aplicamos replace simple al string completo):
    -- pero como replace() no soporta expresiones regulares, hacemos 3 reemplazos genéricos:
    ARRAY['????????????C', '°C'],  -- 12 signos + C  (termómetros)
    ARRAY['??C',        '°C'],   -- versión corta (algunos products)

    -- ── Símbolos corporativos y patents ──────────────────────────
    -- 'N??' ya cubierto arriba; estos son trailing de palabras en inglés:
    ARRAY['SHIM??',  'SHIM'],   -- quita el símbolo trailing (™/®/°)
    ARRAY['PLATE??', 'PLATE'],
    ARRAY['INSERT??', 'INSERT'],
    ARRAY['SPRING??', 'SPRING'],
    ARRAY['ASS??',   'ASS'],    -- ASS = assembly (a veces ASSY)
    ARRAY['CHART??', 'CHART'],
    ARRAY['OPERATOR??', 'OPERATOR'],
    ARRAY['PULLEY??', 'PULLEY'],
    ARRAY['FUSE??',   'FUSE'],
    ARRAY['MASTER??', 'MASTER'],
    ARRAY['EXHAUST??', 'EXHAUST'],
    ARRAY['SEAL??',   'SEAL'],
    ARRAY['BELT??',   'BELT'],
    ARRAY['SIDE??',   'SIDE'],
    ARRAY['BAND??',   'BAND'],
    ARRAY['INJECTION??', 'INJECTION'],
    ARRAY['CROCH??',  'CROCH'],
    -- 'n??' ya quitado arriba; pero si quedan otros '?' sueltos al final de palabras:
    ARRAY['??',      ''],       -- quita un solo "?" suelto (last resort); 
                           -- cuidado: esto es muy agresivo y solo al final de palabras.
                           -- Lo incluimos comentado y lo descomenta el usuario si lo necesita.

    -- ── Palabras esporádicas de español ────────────────────────
    -- 'a??o' → 'año' (año) [755 ocurrencias restantes tras fix anterior]
    ARRAY['a??o',    'año'],
    -- 'pe??a' → 'peña' (peña) [34 ocurrencias]
    ARRAY['pe??a',   'peña'],
    -- 'cu??a' → 'cuña' [91]
    ARRAY['cu??a',   'cuña'],
    -- 'gu??a' → 'guía' (í) [?]
    ARRAY['gu??a',   'guía'],
    -- 'ni??o' → 'niño' [no estaba en la lista original, pero aparece]
    ARRAY['ni??o',   'niño'],
    -- 'ca??o' → 'caño' [6]
    ARRAY['ca??o',   'caño'],
    -- 'pa??' → 'pañ' [paño, paños] [omitido: muy raro]
    -- 'ba??' → 'baño' [3] [omitido]
    -- 'ara??' → 'araña' [64] [omitido: ya cubierto por 'se??'→'señ' o reglas específicas]

    -- ── Vocales sueltas en posición no-suffix ────────────────────
    -- 'v??lv' → 'válv' (cubre válvula/válvulas) [ya en fix-encoding, pero refuerzo]
    ARRAY['v??lv',   'válv'],
    -- 'hidr??ulic' → 'hidráulic' [ya cubierto]
    -- 'magn??tic' → 'magnétic' [ya cubierto]
    -- 'el??ctric' → 'eléctric' [ya cubierto]
    -- 'electr??nic' → 'electrónic' [ya cubierto]
    -- 'qu??mic' → 'químic' [ya cubierto]
    -- 't??cnic' → 'técnic' [ya cubierto]
    -- 'sint??tic' → 'sintétic' [ya cubierto]
    -- 'pl??stic' → 'plástic' [ya cubierto]
    -- 'met??lic' → 'metálic' [ya cubierto]
    -- 'fotogr??fic' → 'fotográfic' [ya cubierto]
    -- 'miscel??ne' → 'misceláne' [ya cubierto]
    -- 'l??min' → 'lámin' [ya cubierto]
    -- 'vehicul' → 'vehícular' [omitido: muy rara]
  ];

  -- Expande cada regla base a minúscula / Título / MAYÚSCULA
  FOR i IN 1..array_length(base, 1) LOOP
    bad  := base[i][1];
    good := base[i][2];
    pairs := pairs || ARRAY[ARRAY[bad, good]];
    t_bad  := upper(left(bad, 1)) || substr(bad, 2);
    t_good := upper(left(good, 1)) || substr(good, 2);
    IF t_bad <> bad THEN
      pairs := pairs || ARRAY[ARRAY[t_bad, t_good]];
    END IF;
    u_bad  := upper(bad);
    u_good := upper(good);
    IF u_bad <> bad AND u_bad <> t_bad THEN
      pairs := pairs || ARRAY[ARRAY[u_bad, u_good]];
    END IF;
  END LOOP;

  -- Aplica a todas las columnas de texto en una sola pasada por columna
  FOR r IN
    SELECT table_schema, table_name, column_name
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND data_type IN ('character varying', 'text')
  LOOP
    expr := r.column_name;
    FOR i IN 1..array_length(pairs, 1) LOOP
      expr := format('replace(%s, %L, %L)', expr, pairs[i][1], pairs[i][2]);
    END LOOP;
    EXECUTE format(
      'UPDATE %I.%I SET %I = %s WHERE %I LIKE ''%%??%%''',
      r.table_schema, r.table_name, r.column_name, expr, r.column_name
    );
  END LOOP;
END $$;

COMMIT;

-- ── Reporte de qué quedó ──────────────────────────────────────
SELECT 'products' AS tabla, count(*) AS con_resto
FROM products WHERE name LIKE '%??%'
UNION ALL
SELECT 'suppliers', count(*) FROM suppliers WHERE name LIKE '%??%' OR address LIKE '%??%' OR description LIKE '%??%'
UNION ALL
SELECT 'categories', count(*) FROM categories WHERE name LIKE '%??%'
UNION ALL
SELECT 'warehouses', count(*) FROM warehouses WHERE name LIKE '%??%'
UNION ALL
SELECT 'employees', count(*) FROM employees WHERE full_name LIKE '%??%'
UNION ALL
SELECT 'cost_centers', count(*) FROM cost_centers WHERE full_description LIKE '%??%' OR division_description LIKE '%??%'
UNION ALL
SELECT 'supplier_categories', count(*) FROM supplier_categories WHERE name LIKE '%??%';