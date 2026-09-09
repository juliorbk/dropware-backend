package com.visco.backend.config;

import io.github.cdimascio.dotenv.Dotenv;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.env.EnvironmentPostProcessor;
import org.springframework.core.Ordered;
import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.core.env.MapPropertySource;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

/**
 * Loads a local {@code .env} file (via {@code dotenv-java}) into the Spring
 * environment as a property source so that {@code ${...}} placeholders in
 * {@code application*.properties} resolve when running outside a platform that
 * injects environment variables (e.g. {@code ./mvnw spring-boot:run}).
 *
 * <p>Existing environment variables always win: values already present in the
 * real OS/process environment (as in Railway, Docker {@code env_file}, or an
 * IDE run configuration) are never overridden by the {@code .env} file.</p>
 */
public class DotenvEnvironmentPostProcessor implements EnvironmentPostProcessor, Ordered {

  private static final String SOURCE_NAME = "dotenv";

  @Override
  public void postProcessEnvironment(ConfigurableEnvironment environment,
                                     SpringApplication application) {
    Path dotenvPath = Path.of(System.getProperty("user.dir"), ".env");
    if (!Files.isRegularFile(dotenvPath)) {
      return;
    }

    Dotenv dotenv;
    try {
      dotenv = Dotenv.configure().directory(dotenvPath.getParent().toString()).load();
    } catch (RuntimeException e) {
      // Missing optional values in the file must not break startup.
      return;
    }

    Set<String> existingKeys = new HashSet<>();
    environment.getSystemEnvironment().forEach((key, value) -> existingKeys.add(key));

    Map<String, Object> values = new HashMap<>();
    dotenv.entries().forEach(entry -> {
      if (!existingKeys.contains(entry.getKey())) {
        values.put(entry.getKey(), entry.getValue());
      }
    });

    if (!values.isEmpty()) {
      environment.getPropertySources()
          .addLast(new MapPropertySource(SOURCE_NAME, values));
    }
  }

  @Override
  public int getOrder() {
    return Ordered.LOWEST_PRECEDENCE;
  }
}
