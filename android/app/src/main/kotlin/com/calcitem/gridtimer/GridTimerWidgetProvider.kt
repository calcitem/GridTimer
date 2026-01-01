package com.calcitem.gridtimer

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * GridTimer home screen widget provider
 * Displays the status of currently running timers
 */
class GridTimerWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // Update all widget instances
        appWidgetIds.forEach { widgetId ->
            updateWidget(context, appWidgetManager, widgetId)
        }
    }

    companion object {
        private const val WIDGET_ACTION_PREFIX = "com.calcitem.gridtimer.WIDGET_ACTION_"
        const val WIDGET_ACTION_OPEN_APP = "${WIDGET_ACTION_PREFIX}OPEN_APP"
        const val WIDGET_ACTION_REFRESH = "${WIDGET_ACTION_PREFIX}REFRESH"

        /**
         * Update widget
         */
        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            widgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.widget_grid_timer)

            // Read data passed from Flutter via SharedPreferences
            val widgetData = HomeWidgetPlugin.getData(context)
            val activeTimersCount = widgetData.getInt("active_timers_count", 0)
            val ringingTimersCount = widgetData.getInt("ringing_timers_count", 0)
            val nearestTimerName = widgetData.getString("nearest_timer_name", null)
            val nearestTimerRemaining = widgetData.getString("nearest_timer_remaining", null)

            // Update display content
            views.setTextViewText(R.id.widget_title, "GridTimer")

            // Status summary
            val statusText = when {
                ringingTimersCount > 0 -> "🔔 $ringingTimersCount 个计时器响铃"
                activeTimersCount > 0 -> "⏱️ $activeTimersCount 个计时器运行中"
                else -> "📱 点击打开应用"
            }
            views.setTextViewText(R.id.widget_status, statusText)

            // Display nearest timer information
            if (nearestTimerName != null && nearestTimerRemaining != null) {
                views.setTextViewText(
                    R.id.widget_nearest_timer,
                    "$nearestTimerName: $nearestTimerRemaining"
                )
                views.setViewVisibility(R.id.widget_nearest_timer, android.view.View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.widget_nearest_timer, android.view.View.GONE)
            }

            // Set click to open app
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)

            // Refresh button
            val refreshIntent = Intent(context, GridTimerWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(widgetId))
            }
            val refreshPendingIntent = PendingIntent.getBroadcast(
                context,
                widgetId,
                refreshIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_refresh_button, refreshPendingIntent)

            // Update widget
            appWidgetManager.updateAppWidget(widgetId, views)
        }

        /**
         * Update all widget instances
         */
        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val widgetIds = appWidgetManager.getAppWidgetIds(
                android.content.ComponentName(context, GridTimerWidgetProvider::class.java)
            )
            widgetIds.forEach { widgetId ->
                updateWidget(context, appWidgetManager, widgetId)
            }
        }
    }
}

