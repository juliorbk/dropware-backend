-- ════════════════════════════════════════════════════════════════════
-- VISCO-SG — Corrige vocales con tilde y ñ que quedaron como "??"
-- ════════════════════════════════════════════════════════════════════
-- Causa: al importar el backup, los caracteres UTF-8 de 2 bytes
-- (á é í ó ú ü ñ, mayúsculas incluidas) se reemplazaron por dos signos
-- de interrogación literales ("??"), perdiendo la letra original.
-- Al ser pérdida irreversible, la solución es un diccionario
-- "subcadena corrupta" -> "subcadena correcta".
--
-- Es idempotente: solo actúa sobre filas que aún contienen "??".
--
-- Ejecutar:
--   docker cp scripts\fix-accents.sql visco_db_dev:/tmp/fix-accents.sql
--   docker exec visco_db_dev psql -U visco_admin -d visco_db -v ON_ERROR_STOP=1 -f /tmp/fix-accents.sql
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
  -- Diccionario base en minúsculas (se expande a 3 variantes de caso).
  base := ARRAY[
    -- sufijos -ción / -sión
    ARRAY['cci??n', 'cción'],
    ARRAY['aci??n', 'ación'],
    ARRAY['eci??n', 'eción'],
    ARRAY['ici??n', 'ición'],
    ARRAY['uci??n', 'ución'],
    ARRAY['xi??n', 'xión'],
    ARRAY['si??n', 'sión'],

    -- ñ
    ARRAY['cig??e??al', 'cigüeñal'],
    ARRAY['cigue??al',  'cigueñal'],
    ARRAY['cig??e',     'cigüe'],
    ARRAY['acompa??',   'acompañ'],
    ARRAY['lara??aga',  'larañaga'],
    ARRAY['casta??eda', 'castañeda'],
    ARRAY['qui??onez',  'quiñonez'],
    ARRAY['qui??ones',  'quiñones'],
    ARRAY['pelda??os',  'peldaños'],
    ARRAY['travesa??o', 'travesaño'],
    ARRAY['monta??o',   'montaño'],
    ARRAY['mari??o',    'mariño'],
    ARRAY['carre??o',   'carreño'],
    ARRAY['brice??o',   'briceño'],
    ARRAY['cede??o',    'cedeño'],
    ARRAY['mu??oz',     'muñoz'],
    ARRAY['mu??on',     'muñon'],
    ARRAY['nu??ez',     'nuñez'],
    ARRAY['se??orita',  'señorita'],
    ARRAY['se??al',     'señal'],
    ARRAY['se??',       'señ'],
    ARRAY['espa??',     'españ'],
    ARRAY['ara??',      'arañ'],
    ARRAY['pesta??',    'pestañ'],
    ARRAY['peque??',    'pequeñ'],
    ARRAY['cu??ete',    'cuñete'],
    ARRAY['cu??a',      'cuña'],
    ARRAY['esta??o',    'estaño'],
    ARRAY['tama??',     'tamañ'],
    ARRAY['pi??on',     'piñon'],
    ARRAY['ca??',       'cañ'],
    ARRAY['pa??',       'pañ'],
    ARRAY['ba??',       'bañ'],
    ARRAY['u??a',       'uña'],
    ARRAY['ni??o',      'niño'],
    ARRAY['caf??',      'café'],

    -- vocales con tilde
    ARRAY['electrov??lvula', 'electroválvula'],
    ARRAY['v??lv',      'válv'],
    ARRAY['hidr??ulic', 'hidráulic'],
    ARRAY['magn??tic',  'magnétic'],
    ARRAY['autom??t',   'automát'],
    ARRAY['m??ltiple',  'múltiple'],
    ARRAY['c??mara',    'cámara'],
    ARRAY['c??mput',    'cómput'],
    ARRAY['c??digo',    'código'],
    ARRAY['c??todo',    'cátodo'],
    ARRAY['m??dulo',    'módulo'],
    ARRAY['m??vil',     'móvil'],
    ARRAY['m??dico',    'médico'],
    ARRAY['el??ctric',  'eléctric'],
    ARRAY['electr??nic','electrónic'],
    ARRAY['qu??mic',    'químic'],
    ARRAY['t??cnic',    'técnic'],
    ARRAY['t??rmic',    'térmic'],
    ARRAY['inform??tic','informátic'],
    ARRAY['perif??ric', 'periféric'],
    ARRAY['sint??tic',  'sintétic'],
    ARRAY['pl??stic',   'plástic'],
    ARRAY['plexigl??s', 'plexiglás'],
    ARRAY['met??lic',   'metálic'],
    ARRAY['fotogr??fic','fotográfic'],
    ARRAY['miscel??ne', 'misceláne'],
    ARRAY['l??min',     'lámin'],
    ARRAY['l??nea',     'línea'],
    ARRAY['l??mpara',   'lámpara'],
    ARRAY['l??quido',   'líquido'],
    ARRAY['veh??cul',   'vehícul'],
    ARRAY['cer??mic',   'cerámic'],
    ARRAY['art??cul',   'artícul'],
    ARRAY['artiller??a','artillería'],
    ARRAY['nitr??gen',  'nitrógen'],
    ARRAY['di??sel',    'diésel'],
    ARRAY['di??metro',  'diámetro'],
    ARRAY['papeler??a', 'papelería'],
    ARRAY['plomer??a',  'plomería'],
    ARRAY['tuber??a',   'tubería'],
    ARRAY['bater??a',   'batería'],
    ARRAY['energ??a',   'energía'],
    ARRAY['cart??n',    'cartón'],
    ARRAY['almac??n',   'almacén'],
    ARRAY['cami??n',    'camión'],
    ARRAY['pist??n',    'pistón'],
    ARRAY['bomb??n',    'bombón'],
    ARRAY['collar??n',  'collarín'],
    ARRAY['cuchar??n',  'cucharón'],
    ARRAY['carb??n',    'carbón'],
    ARRAY['tap??n',     'tapón'],
    ARRAY['v??ver',     'víver'],
    ARRAY['n??mero',    'número'],
    ARRAY['n??cleo',    'núcleo'],
    ARRAY['r??pido',    'rápido'],
    ARRAY['v??stago',   'vástago'],
    ARRAY['gr??a',      'grúa'],
    ARRAY['port??til',  'portátil'],
    ARRAY['??xido',     'óxido'],
    ARRAY['??til',      'útil'],
    ARRAY['gu??a',      'guía'],
    ARRAY['vac??o',     'vacío'],
    ARRAY['el??stico',  'elástico'],
    ARRAY['man??metro', 'manómetro'],
    ARRAY['amper??metro','amperímetro'],
    ARRAY['potenci??metro','potenciómetro'],
    ARRAY['cil??ndro',  'cilindro'],
    ARRAY['buj??a',     'bujía'],
    ARRAY['est??ndar',  'estándar'],
    ARRAY['instant??nea','instantánea'],
    ARRAY['anal??gico', 'analógico'],
    ARRAY['an??lisis',  'análisis'],
    ARRAY['catal??tico','catalítico'],
    ARRAY['sat??lite',  'satélite'],
    ARRAY['b??sic',     'básic'],
    ARRAY['cr??tic',    'crític'],
    ARRAY['f??sic',     'físic'],
    ARRAY['c??lculo',   'cálculo'],
    ARRAY['s??lido',    'sólido'],
    ARRAY['m??quina',   'máquina']
  ];

  -- Expande cada regla base a minúscula / Título / MAYÚSCULA.
  FOR i IN 1..array_length(base, 1) LOOP
    bad  := base[i][1];
    good := base[i][2];
    pairs := pairs || ARRAY[ARRAY[bad, good]];
    t_bad  := upper(left(bad, 1))  || substr(bad, 2);
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

  -- Aplica las reglas a todas las columnas de texto, en un único UPDATE
  -- por columna (una sola pasada por tabla).
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

-- ── Cuántas filas quedan aún con "??" (símbolos especiales: °, ®, ™…) ──
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
