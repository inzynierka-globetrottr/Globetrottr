package sniezynki.agh.globetrottr.quest;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/quests")
@RequiredArgsConstructor
public class QuestController {

    private final QuestService questService;

    @GetMapping("/{userId}")
    public ResponseEntity<List<QuestResponseDto>> getUserQuests(@PathVariable UUID userId) {
        return ResponseEntity.ok(questService.getAllQuestsForSidebar(userId));
    }

    @PostMapping("/{userId}/start/{questId}")
    public ResponseEntity<Void> startQuest(@PathVariable UUID userId, @PathVariable Long questId) {
        questService.startQuest(userId, questId);
        return ResponseEntity.ok().build();
    }
}
