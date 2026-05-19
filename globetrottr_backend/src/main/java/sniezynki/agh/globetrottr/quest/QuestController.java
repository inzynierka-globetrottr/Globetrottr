package sniezynki.agh.globetrottr.quest;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/quests")
@RequiredArgsConstructor
public class QuestController {

    private final QuestService questService;

    @GetMapping("/{userId}")
    public ResponseEntity<List<QuestResponseDto>> getUserQuests(@PathVariable UUID userId) {
        return ResponseEntity.ok(questService.getAllQuestsForUser(userId));
    }
}
