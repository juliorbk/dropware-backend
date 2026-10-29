package com.dropware.backend.models.dtos;

import jakarta.validation.constraints.NotBlank;

// Request payload for updating an existing product category.
public record UpdateCategoryRequest(
  @NotBlank(message = "El nombre es obligatorio") String name,
  Long parentId
) {}
