package com.visco.backend.models.dtos;

import com.visco.backend.models.entities.Employee;

// Response DTO with employee details.
public record EmployeeResponseDto(
  Long id,
  String fullName,
  String documentNumber,
  Boolean isActive
) {
  public static EmployeeResponseDto fromEntity(Employee emp) {
    return new EmployeeResponseDto(
      emp.getId(),
      emp.getFullName(),
      emp.getDocumentNumber(),
      emp.isActive()
    );
  }
}
