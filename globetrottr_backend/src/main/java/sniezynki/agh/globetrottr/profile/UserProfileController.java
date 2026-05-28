package sniezynki.agh.globetrottr.profile;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import sniezynki.agh.globetrottr.profile.dto.UpdateBioRequest;
import sniezynki.agh.globetrottr.profile.dto.UserProfileResponse;

import java.util.Map;

@RestController
@RequestMapping("/api/profile")
@RequiredArgsConstructor
public class UserProfileController {
    private final UserProfileService userProfileService;

    @GetMapping("/me")
    public ResponseEntity<UserProfileResponse> getMyProfile() {
        String username = SecurityContextHolder.getContext().getAuthentication().getName();
        return ResponseEntity.ok(userProfileService.getMyProfile(username));
    }

    @GetMapping("/{friendUsername}")
    public ResponseEntity<UserProfileResponse> getFriendProfile(@PathVariable String friendUsername) {
        String username = SecurityContextHolder.getContext().getAuthentication().getName();
        return ResponseEntity.ok(userProfileService.getFriendProfile(username,friendUsername));
    }

    @PatchMapping("/bio")
    public ResponseEntity<Void> updateBio(@Valid @RequestBody UpdateBioRequest request) {
        String username = SecurityContextHolder.getContext().getAuthentication().getName();
        userProfileService.updateBio(username, request.bio());
        return ResponseEntity.ok().build();
    }

    @PostMapping(value = "/avatar", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<Map<String, String>> uploadAvatar(@RequestParam("file") MultipartFile file) {
        String username = SecurityContextHolder.getContext().getAuthentication().getName();
        String avatarUrl = userProfileService.uploadAvatar(username, file);

        return ResponseEntity.ok(Map.of("avatarUrl", avatarUrl));
    }
}
