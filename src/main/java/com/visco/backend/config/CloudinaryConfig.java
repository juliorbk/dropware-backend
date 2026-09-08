package com.visco.backend.config;

import com.cloudinary.Cloudinary;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class CloudinaryConfig {

  private static final String PLACEHOLDER_URL = "cloudinary://fake:fake@fake";

  @Value("${cloudinary.url:}")
  private String cloudinaryUrl;

  @Bean
  public Cloudinary cloudinary() {
    String url = (cloudinaryUrl == null || cloudinaryUrl.isBlank()) ? PLACEHOLDER_URL : cloudinaryUrl;
    return new Cloudinary(url);
  }
}
