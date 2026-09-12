package com.styleora;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class ProductBySubCategorySecurityIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void productBySubCategoryEndpointIsPublicForAnonymousUsers() throws Exception {
        mockMvc.perform(get("/products/by-subcategory/999999"))
                .andExpect(status().isOk());
    }
}
