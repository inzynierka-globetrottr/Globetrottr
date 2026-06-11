package sniezynki.agh.globetrottr.region;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/regions")
@RequiredArgsConstructor
public class AdminRegionController {

    private final RegionImportService importService;

    //TODO: add admin protection

    @PostMapping("/import-cities")
    public ResponseEntity<String> importCities() {
        importService.importRegionsFromGeoJson("classpath:data/poland_cities.geojson", RegionType.CITY, "JPT_NAZWA_");
        return ResponseEntity.ok("Polish cities import completed!");
    }

    @PostMapping("/import-countries")
    public ResponseEntity<String> importCountries() {
        importService.importRegionsFromGeoJson("classpath:data/countries.geojson", RegionType.COUNTRY, "ADMIN");
        return ResponseEntity.ok("Countries import completed!");
    }
}