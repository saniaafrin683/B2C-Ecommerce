package com.styleora.controller;

import com.styleora.model.ReportSummary;
import com.styleora.service.ReportService;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/reports")
public class ReportController {

    private final ReportService reportService;

    public ReportController(ReportService reportService) {
        this.reportService = reportService;
    }

    @GetMapping("/summary")
    public ReportSummary getSummary(@RequestParam(required = false) String range) {
        return reportService.getSummary(range);
    }

    @GetMapping("/revenue/monthly")
    public List<Map<String, Object>> getMonthlyRevenue(@RequestParam(required = false) String range) {
        return reportService.getMonthlyRevenue(range);
    }

    @GetMapping("/orders/monthly")
    public List<Map<String, Object>> getMonthlyOrders(@RequestParam(required = false) String range) {
        return reportService.getMonthlyOrders(range);
    }

    @GetMapping("/top-products")
    public List<Map<String, Object>> getTopProducts(@RequestParam(required = false) String range) {
        return reportService.getTopProducts(range);
    }

    @GetMapping("/top-customers")
    public List<Map<String, Object>> getTopCustomers(@RequestParam(required = false) String range) {
        return reportService.getTopCustomers(range);
    }

    @GetMapping("/export/csv")
    public ResponseEntity<String> exportCsv(@RequestParam(required = false) String range) {
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=styleora-dashboard-report.csv")
                .contentType(new MediaType("text", "csv"))
                .body(reportService.exportCsv(range));
    }
}
