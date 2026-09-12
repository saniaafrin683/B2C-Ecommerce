package com.styleora.service;

import com.styleora.dao.ReportDao;
import com.styleora.model.ReportSummary;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

@Service
public class ReportService {

    private final ReportDao reportDao;

    public ReportService(ReportDao reportDao) {
        this.reportDao = reportDao;
    }

    public ReportSummary getSummary(String range) {
        return reportDao.getSummary(range);
    }

    public List<Map<String, Object>> getMonthlyRevenue(String range) {
        return reportDao.getMonthlyRevenue(range);
    }

    public List<Map<String, Object>> getMonthlyOrders(String range) {
        return reportDao.getMonthlyOrders(range);
    }

    public List<Map<String, Object>> getTopProducts(String range) {
        return reportDao.getTopProducts(range);
    }

    public List<Map<String, Object>> getTopCustomers(String range) {
        return reportDao.getTopCustomers(range);
    }

    public String exportCsv(String range) {
        return reportDao.exportCsv(range);
    }
}
