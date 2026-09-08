package com.visco.backend.repositories;

import com.visco.backend.models.entities.Employee;
import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

// Repository for Employee entities.
public interface EmployeeRepository extends JpaRepository<Employee, Long> {
  // Finds all employees sorted by name.
  @Query(
    value = "SELECT e FROM Employee e ORDER BY e.fullName ASC",
    countQuery = "SELECT COUNT(e) FROM Employee e"
  )
  Page<Employee> findAllWithFetch(Pageable pageable);

  // Finds an employee by their unique document number.
  Optional<Employee> findByDocumentNumber(String documentNumber);
}
