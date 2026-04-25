package sniezynki.agh.globetrottr.sync;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import sniezynki.agh.globetrottr.sync.dto.SyncRequest;

@RestController
@RequestMapping("api/map")
@RequiredArgsConstructor
public class SyncController {

    private final SyncService syncService;

    @PostMapping("/sync")
    public ResponseEntity<?> sync(@RequestBody SyncRequest syncRequest) {
        String username = SecurityContextHolder.getContext().getAuthentication().getName();

        syncService.processPoints(syncRequest.points(), username);
        return ResponseEntity.ok("Sync complete");
    }
}
