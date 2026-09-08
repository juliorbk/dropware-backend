package com.visco.backend.models.dtos;

import com.visco.backend.models.entities.User;
import com.visco.backend.models.entities.UserRole;
import java.util.UUID;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
// Response DTO with user profile information.
public class UserDTO {

    private UUID id;
    private String name;
    private String email;
    private UserRole role;

    private String profilePictureUrl;

    public static UserDTO fromUser(User user) {
        if (user == null) {
            return null;
        }
        return UserDTO.builder()
            .id(user.getId())
            .name(user.getName())
            .email(user.getEmail())
            .role(user.getRole())
            .profilePictureUrl(user.getProfilePictureUrl())
            .build();
    }
}
