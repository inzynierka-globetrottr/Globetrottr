package sniezynki.agh.globetrottr.exception;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

class GlobalExceptionHandlerTest {

    private final GlobalExceptionHandler handler = new GlobalExceptionHandler();

    @Test
    void shouldMapResourceNotFoundToNotFoundStatus() {
        ResponseEntity<Map<String, String>> response =
                handler.handleResourceNotFound(new ResourceNotFoundException("Quest not found"));

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
        assertThat(response.getBody()).containsEntry("error", "Quest not found");
    }
}
