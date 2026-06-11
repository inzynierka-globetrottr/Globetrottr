package sniezynki.agh.globetrottr.region;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.Resource;
import org.springframework.core.io.ResourceLoader;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.InputStream;

@Slf4j
@Service
@RequiredArgsConstructor
public class RegionImportService {

    private final JdbcTemplate jdbcTemplate;
    private final ResourceLoader resourceLoader;

    private final ObjectMapper objectMapper;

    private final RegionRepository regionRepository;

    @Transactional
    public void importRegionsFromGeoJson(String resourcePath, RegionType type, String namePropertyKey) {
        log.info("Started import from: {}", resourcePath);
        try {
            Resource resource = resourceLoader.getResource(resourcePath);
            try (InputStream is = resource.getInputStream()) {
                JsonNode root = objectMapper.readTree(is);
                JsonNode features = root.get("features");

                if (features == null || !features.isArray()) {
                    String errorMessage = "Incorrect GeoJSON format: 'features' node is missing or is not an array in " + resourcePath;
                    log.error("Incorrect geojson format");
                    throw new IllegalArgumentException(errorMessage);
                }

                for (JsonNode feature : features) {
                    JsonNode properties = feature.get("properties");
                    if (properties == null || !properties.has(namePropertyKey)) continue;

                    String name = properties.get(namePropertyKey).asText();

                    if (regionRepository.existsByName(name)) {
                        log.debug("Region {} exists in database", name);
                        continue;
                    }

                    String geometryJson = feature.get("geometry").toString();
                    String typeString = type.name();

                    String sql = """
                            INSERT INTO regions (name, type, geom, total_area_km2)
                            VALUES (
                                ?, 
                                ?, 
                                ST_Multi(ST_SetSRID(ST_GeomFromGeoJSON(?), 4326)),
                                ST_Area(ST_Multi(ST_SetSRID(ST_GeomFromGeoJSON(?), 4326))::geography) / 1000000.0
                            )
                            """;
                    jdbcTemplate.update(sql, name, typeString, geometryJson, geometryJson);
                }
                log.info("Finished import from: {}", resourcePath);
            }
        } catch (Exception e) {
            log.error("error during import from: {}", resourcePath, e);
            throw new RuntimeException("Import failed", e);
        }
    }
}