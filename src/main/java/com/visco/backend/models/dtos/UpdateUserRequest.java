package com.visco.backend.models.dtos;

import com.visco.backend.models.entities.UserRole;
import jakarta.validation.constraints.NotNull;

// Request payload for updating a user's role.
public record UpdateUserRequest(
    @NotNull(message = "El rol es obligatorio") UserRole role
) {}
