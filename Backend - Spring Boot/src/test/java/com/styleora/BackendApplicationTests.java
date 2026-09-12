package com.styleora;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import com.styleora.dto.CurrentStockSummaryDto;
import com.styleora.model.ReportSummary;
import com.styleora.service.InventoryService;
import com.styleora.service.ReportService;
import org.springframework.web.servlet.mvc.method.RequestMappingInfo;
import org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerMapping;

import java.util.List;
import java.util.Set;

@SpringBootTest
class BackendApplicationTests {

	@Autowired
	private RequestMappingHandlerMapping requestMappingHandlerMapping;

	@Autowired
	private ReportService reportService;

	@Autowired
	private InventoryService inventoryService;

	@Test
	void contextLoads() {
	}

	@Test
	void authLoginEndpointIsRegistered() {
		boolean hasAuthLoginMapping = requestMappingHandlerMapping.getHandlerMethods()
			.keySet()
			.stream()
			.anyMatch(this::isAuthLoginPostMapping);

		org.junit.jupiter.api.Assertions.assertTrue(hasAuthLoginMapping);
	}

	@Test
	void couponApplyEndpointIsRegistered() {
		boolean hasCouponApplyMapping = requestMappingHandlerMapping.getHandlerMethods()
			.keySet()
			.stream()
			.anyMatch(this::isCouponApplyPostMapping);

		org.junit.jupiter.api.Assertions.assertTrue(hasCouponApplyMapping);
	}

	@Test
	void currentStockEndpointIsRegistered() {
		boolean hasCurrentStockMapping = requestMappingHandlerMapping.getHandlerMethods()
			.keySet()
			.stream()
			.anyMatch(this::isCurrentStockGetMapping);

		org.junit.jupiter.api.Assertions.assertTrue(hasCurrentStockMapping);
	}

	@Test
	void purchaseEndpointsAreRegistered() {
		boolean hasPurchaseCreateMapping = requestMappingHandlerMapping.getHandlerMethods()
			.keySet()
			.stream()
			.anyMatch(this::isPurchaseCreatePostMapping);
		boolean hasPurchaseDetailsMapping = requestMappingHandlerMapping.getHandlerMethods()
			.keySet()
			.stream()
			.anyMatch(this::isPurchaseDetailsGetMapping);

		org.junit.jupiter.api.Assertions.assertTrue(hasPurchaseCreateMapping);
		org.junit.jupiter.api.Assertions.assertTrue(hasPurchaseDetailsMapping);
	}

	@Test
	void customerMyReviewsEndpointIsRegistered() {
		boolean hasMyReviewsMapping = requestMappingHandlerMapping.getHandlerMethods()
			.keySet()
			.stream()
			.anyMatch(this::isCustomerMyReviewsGetMapping);

		org.junit.jupiter.api.Assertions.assertTrue(hasMyReviewsMapping);
	}

	private boolean isAuthLoginPostMapping(RequestMappingInfo mappingInfo) {
		Set<String> patterns = mappingInfo.getPatternValues();
		Set<org.springframework.web.bind.annotation.RequestMethod> methods =
			mappingInfo.getMethodsCondition().getMethods();

		return patterns.contains("/auth/login")
			&& methods.contains(org.springframework.web.bind.annotation.RequestMethod.POST);
	}

	private boolean isCouponApplyPostMapping(RequestMappingInfo mappingInfo) {
		Set<String> patterns = mappingInfo.getPatternValues();
		Set<org.springframework.web.bind.annotation.RequestMethod> methods =
			mappingInfo.getMethodsCondition().getMethods();

		return patterns.contains("/coupons/apply")
			&& methods.contains(org.springframework.web.bind.annotation.RequestMethod.POST);
	}

	private boolean isCurrentStockGetMapping(RequestMappingInfo mappingInfo) {
		Set<String> patterns = mappingInfo.getPatternValues();
		Set<org.springframework.web.bind.annotation.RequestMethod> methods =
			mappingInfo.getMethodsCondition().getMethods();

		return patterns.contains("/inventory/current-stock")
			&& methods.contains(org.springframework.web.bind.annotation.RequestMethod.GET);
	}

	private boolean isPurchaseCreatePostMapping(RequestMappingInfo mappingInfo) {
		Set<String> patterns = mappingInfo.getPatternValues();
		Set<org.springframework.web.bind.annotation.RequestMethod> methods =
			mappingInfo.getMethodsCondition().getMethods();

		return patterns.contains("/purchases/create")
			&& methods.contains(org.springframework.web.bind.annotation.RequestMethod.POST);
	}

	private boolean isPurchaseDetailsGetMapping(RequestMappingInfo mappingInfo) {
		Set<String> patterns = mappingInfo.getPatternValues();
		Set<org.springframework.web.bind.annotation.RequestMethod> methods =
			mappingInfo.getMethodsCondition().getMethods();

		return patterns.contains("/purchases/details/{id}")
			&& methods.contains(org.springframework.web.bind.annotation.RequestMethod.GET);
	}

	private boolean isCustomerMyReviewsGetMapping(RequestMappingInfo mappingInfo) {
		Set<String> patterns = mappingInfo.getPatternValues();
		Set<org.springframework.web.bind.annotation.RequestMethod> methods =
			mappingInfo.getMethodsCondition().getMethods();

		return patterns.contains("/reviews/my")
			&& methods.contains(org.springframework.web.bind.annotation.RequestMethod.GET);
	}

	@Test
	void dashboardSummaryReturnsCoreMetrics() {
		ReportSummary summary = reportService.getSummary(null);

		org.junit.jupiter.api.Assertions.assertNotNull(summary);
		org.junit.jupiter.api.Assertions.assertNotNull(summary.getTotalOrders());
		org.junit.jupiter.api.Assertions.assertNotNull(summary.getTotalProducts());
		org.junit.jupiter.api.Assertions.assertNotNull(summary.getTotalCustomers());
		org.junit.jupiter.api.Assertions.assertNotNull(summary.getTotalRevenue());
	}

	@Test
	void currentStockSummaryLoads() {
		List<CurrentStockSummaryDto> summaries = inventoryService.getCurrentStockSummaries();

		org.junit.jupiter.api.Assertions.assertNotNull(summaries);
	}

}
