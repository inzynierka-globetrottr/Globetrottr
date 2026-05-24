package sniezynki.agh.globetrottr.friend;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotNull;
import lombok.*;
import sniezynki.agh.globetrottr.user.User;

import java.sql.Timestamp;

@Entity
@Table(name = "friends", uniqueConstraints = {
        @UniqueConstraint(
                name = "uc_friends_sender_receiver",
                columnNames = {"sender_id", "receiver_id"}
        )
})

@Getter @Setter
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class Friendship {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "sender_id", referencedColumnName = "user_id")
    @NotNull
    private User sender;

    @ManyToOne
    @JoinColumn(name = "receiver_id", referencedColumnName = "user_id")
    @NotNull
    private User receiver;

    @Enumerated(EnumType.STRING)
    @NotNull
    private InviteStatus status;

    @Column(name = "created_at")
    private Timestamp createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = new Timestamp(System.currentTimeMillis());
    }
}
