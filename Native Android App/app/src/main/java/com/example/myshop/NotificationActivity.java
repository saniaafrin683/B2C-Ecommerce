package com.example.myshop;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Typeface;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.widget.LinearLayout;
import android.widget.TextView;

import java.util.ArrayList;
import java.util.List;

public class NotificationActivity extends Activity {
    private LinearLayout notificationsContainer;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        ThemeManager.applyTheme(this);
        setContentView(R.layout.activity_notification);

        findViewById(R.id.backButton).setOnClickListener(view -> finish());
        notificationsContainer = findViewById(R.id.notificationsContainer);
        bindNotifications(createDemoNotifications());
    }

    private void bindNotifications(List<NotificationItem> notifications) {
        notificationsContainer.removeAllViews();
        for (NotificationItem notification : notifications) {
            notificationsContainer.addView(createNotificationCard(notification));
        }
    }

    private View createNotificationCard(NotificationItem notification) {
        LinearLayout card = new LinearLayout(this);
        card.setOrientation(LinearLayout.HORIZONTAL);
        card.setGravity(Gravity.CENTER_VERTICAL);
        card.setPadding(dp(14), dp(14), dp(14), dp(14));
        card.setBackgroundResource(R.drawable.bg_card);
        card.setClickable(true);
        card.setFocusable(true);
        card.setOnClickListener(view -> openNotificationTarget(notification));

        LinearLayout.LayoutParams cardParams = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
        );
        cardParams.setMargins(0, 0, 0, dp(12));
        card.setLayoutParams(cardParams);

        TextView iconText = new TextView(this);
        iconText.setText(notification.shortLabel);
        iconText.setTextColor(getColor(R.color.white));
        iconText.setTextSize(12);
        iconText.setTypeface(null, Typeface.BOLD);
        iconText.setGravity(Gravity.CENTER);
        iconText.setBackgroundResource(notification.offer ? R.drawable.bg_discount_badge : R.drawable.bg_primary_button);
        card.addView(iconText, new LinearLayout.LayoutParams(dp(48), dp(48)));

        LinearLayout content = new LinearLayout(this);
        content.setOrientation(LinearLayout.VERTICAL);
        LinearLayout.LayoutParams contentParams = new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1);
        contentParams.setMargins(dp(12), 0, 0, 0);
        card.addView(content, contentParams);

        TextView titleText = new TextView(this);
        titleText.setText(notification.title);
        titleText.setTextColor(getColor(R.color.text_primary));
        titleText.setTextSize(16);
        titleText.setTypeface(null, Typeface.BOLD);
        content.addView(titleText);

        TextView messageText = new TextView(this);
        messageText.setText(notification.message);
        messageText.setTextColor(getColor(R.color.text_secondary));
        messageText.setTextSize(14);
        messageText.setLineSpacing(dp(2), 1.0f);
        messageText.setPadding(0, dp(4), 0, 0);
        content.addView(messageText);

        TextView timeText = new TextView(this);
        timeText.setText(notification.time);
        timeText.setTextColor(getColor(R.color.primary));
        timeText.setTextSize(12);
        timeText.setTypeface(null, Typeface.BOLD);
        timeText.setPadding(0, dp(8), 0, 0);
        content.addView(timeText);

        return card;
    }

    private List<NotificationItem> createDemoNotifications() {
        List<NotificationItem> notifications = new ArrayList<>();
        notifications.add(new NotificationItem("ORD", "Order placed", "Your StyleOra order has been placed successfully.", "Just now", Target.ORDERS, false));
        notifications.add(new NotificationItem("OK", "Order confirmed", "We confirmed your order and started preparing your items.", "20 min ago", Target.ORDERS, false));
        notifications.add(new NotificationItem("SHP", "Order shipped", "Your package is on the way. Track it from My Orders.", "Today", Target.ORDERS, false));
        notifications.add(new NotificationItem("29%", "Hot deal offer", "Fresh fashion deals are live for a limited time.", "Today", Target.HOT_DEALS, true));
        notifications.add(new NotificationItem("COUP", "Coupon offer", "Use WELCOME10 or STYLEORA50 at checkout for instant savings.", "This week", Target.PRODUCTS, true));
        return notifications;
    }

    private void openNotificationTarget(NotificationItem notification) {
        if (notification.target == Target.ORDERS) {
            startActivity(new Intent(this, OrdersActivity.class));
            return;
        }
        Intent intent = new Intent(this, ProductActivity.class);
        if (notification.target == Target.HOT_DEALS) {
            intent.putExtra(ProductActivity.EXTRA_TITLE, "Hot Deals");
            intent.putExtra(ProductActivity.EXTRA_HOT_DEALS, true);
        }
        startActivity(intent);
    }

    private int dp(int value) {
        return (int) (value * getResources().getDisplayMetrics().density);
    }

    private enum Target {
        ORDERS,
        PRODUCTS,
        HOT_DEALS
    }

    private static class NotificationItem {
        private final String shortLabel;
        private final String title;
        private final String message;
        private final String time;
        private final Target target;
        private final boolean offer;

        private NotificationItem(String shortLabel, String title, String message, String time, Target target, boolean offer) {
            this.shortLabel = shortLabel;
            this.title = title;
            this.message = message;
            this.time = time;
            this.target = target;
            this.offer = offer;
        }
    }
}
