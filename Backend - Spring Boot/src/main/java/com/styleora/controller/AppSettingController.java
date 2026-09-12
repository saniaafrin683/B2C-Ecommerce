package com.styleora.controller;

import com.styleora.model.AppSetting;
import com.styleora.service.AppSettingService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/settings")
public class AppSettingController {

    private final AppSettingService appSettingService;

    public AppSettingController(AppSettingService appSettingService) {
        this.appSettingService = appSettingService;
    }

    @PostMapping("/save")
    public ResponseEntity<AppSetting> saveSetting(@RequestBody AppSetting appSetting) {
        appSetting.setId(null);
        return ResponseEntity.status(HttpStatus.CREATED).body(appSettingService.saveSetting(appSetting));
    }

    @GetMapping
    public ResponseEntity<AppSetting> getCurrentSetting() {
        AppSetting appSetting = appSettingService.getCurrentSetting();
        if (appSetting == null) {
            return ResponseEntity.noContent().build();
        }

        return ResponseEntity.ok(appSetting);
    }

    @GetMapping("/current")
    public ResponseEntity<AppSetting> getCurrentSettingLegacy() {
        return getCurrentSetting();
    }

    @PutMapping("/update/{id}")
    public ResponseEntity<AppSetting> updateSetting(@PathVariable Long id, @RequestBody AppSetting appSetting) {
        AppSetting updatedSetting = appSettingService.updateSetting(id, appSetting);
        if (updatedSetting == null) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.ok(updatedSetting);
    }

    @DeleteMapping("/delete/{id}")
    public ResponseEntity<Void> deleteSetting(@PathVariable Long id) {
        boolean deleted = appSettingService.deleteSetting(id);
        if (!deleted) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.noContent().build();
    }
}
