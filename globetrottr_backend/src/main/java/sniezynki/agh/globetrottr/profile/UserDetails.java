package sniezynki.agh.globetrottr.profile;

import jakarta.persistence.*;
import lombok.*;
import sniezynki.agh.globetrottr.user.User;

@Entity
@Table(name = "user_details")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserDetails {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne
    @JoinColumn(name = "user_id", referencedColumnName = "user_id", nullable = false)
    private User user;

    @Column(name = "avatar_url", length = 500)
    private String avatarUrl;

    @Column(name = "bio", length = 255)
    private String bio;
}
