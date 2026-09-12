package com.styleora.controller;

import com.styleora.dto.ReturnRequestCreateRequest;
import com.styleora.dto.ReturnRequestStatusUpdateRequest;
import com.styleora.model.ReturnRequest;
import com.styleora.security.AuthenticatedUser;
import com.styleora.service.ReturnRequestService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.security.core.annotation.AuthenticationPrincipal;

import java.util.List;

@RestController
@RequestMapping("/returns")
public class ReturnRequestController {

    private final ReturnRequestService returnRequestService;

    public ReturnRequestController(ReturnRequestService returnRequestService) {
        this.returnRequestService = returnRequestService;
    }

    @PostMapping("/request")
    public ResponseEntity<ReturnRequest> requestReturn(
            @RequestBody ReturnRequestCreateRequest request,
            @AuthenticationPrincipal AuthenticatedUser authenticatedUser
    ) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(returnRequestService.createReturnRequest(request, authenticatedUser));
    }

    @GetMapping("/customer/{customerId}")
    public List<ReturnRequest> getCustomerReturnRequests(
            @PathVariable Long customerId,
            @AuthenticationPrincipal AuthenticatedUser authenticatedUser
    ) {
        return returnRequestService.getCustomerReturnRequests(customerId, authenticatedUser);
    }

    @PutMapping("/status/{id}")
    public ResponseEntity<ReturnRequest> updateReturnRequestStatus(
            @PathVariable Long id,
            @RequestBody ReturnRequestStatusUpdateRequest request
    ) {
        return ResponseEntity.ok(returnRequestService.updateReturnRequestStatus(id, request));
    }

    @PostMapping("/create")
    public ResponseEntity<ReturnRequest> createReturnRequest(@RequestBody ReturnRequestCreateRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(returnRequestService.createReturnRequestFromAdmin(request));
    }

    @GetMapping({"", "/list"})
    public List<ReturnRequest> getAllReturnRequests() {
        return returnRequestService.getAllReturnRequests();
    }

    @GetMapping("/{id}")
    public ResponseEntity<ReturnRequest> getReturnRequestById(@PathVariable Long id) {
        ReturnRequest returnRequest = returnRequestService.getReturnRequestById(id);
        return ResponseEntity.ok(returnRequest);
    }

    @PutMapping("/update/{id}")
    public ResponseEntity<ReturnRequest> updateReturnRequest(@PathVariable Long id, @RequestBody ReturnRequestStatusUpdateRequest request) {
        return ResponseEntity.ok(returnRequestService.updateReturnRequestStatus(id, request));
    }

    @DeleteMapping("/delete/{id}")
    public ResponseEntity<Void> deleteReturnRequest(@PathVariable Long id) {
        boolean deleted = returnRequestService.deleteReturnRequest(id);
        if (!deleted) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.noContent().build();
    }
}
