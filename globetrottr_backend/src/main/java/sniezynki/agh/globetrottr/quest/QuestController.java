package sniezynki.agh.globetrottr.quest;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/quests")
@RequiredArgsConstructor
public class QuestController {

    private final QuestService questService;

    @GetMapping("/me")
    public ResponseEntity<List<QuestResponseDto>> getMyQuests() {
        String username = SecurityContextHolder.getContext().getAuthentication().getName();
        return ResponseEntity.ok(questService.getAllQuestsForSidebar(username));
    }

    @PostMapping("/me/start/{questId}")
    public ResponseEntity<Void> startQuest(@PathVariable Long questId) {
        String username = SecurityContextHolder.getContext().getAuthentication().getName();
        questService.startQuest(username, questId);
        return ResponseEntity.ok().build();
    }
}
