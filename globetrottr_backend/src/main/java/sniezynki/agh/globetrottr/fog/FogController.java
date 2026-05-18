package sniezynki.agh.globetrottr.fog;

import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/fog")
@RequiredArgsConstructor
public class FogController {
    private final FogService fogService;

    @GetMapping(value = "/me", produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<String> getMyFog() {
        String username = SecurityContextHolder.getContext().getAuthentication().getName();
        return ResponseEntity.ok(fogService.getUserFogGeoJson(username));
    }

    @GetMapping(value = "/{friendUsername}", produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<String> getFriendFog(@PathVariable String friendUsername) {
        String username = SecurityContextHolder.getContext().getAuthentication().getName();
        return ResponseEntity.ok(fogService.getFriendFogGeoJson(username, friendUsername));

    }


}
