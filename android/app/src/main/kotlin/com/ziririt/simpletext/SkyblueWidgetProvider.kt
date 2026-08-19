package com.ziririt.simpletext

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject

/**
 * 홈 화면 위젯 — 그리기만 한다.
 *
 * 무엇을 그릴지는 다트가 정해서 넘긴다(lib/core/widget_feed.dart).
 * 쓸 말도 다트가 담아 보낸다 — 아홉 언어짜리 말 뭉치가 다트·코틀린·
 * 스위프트 세 군데로 갈라지면 반드시 어긋난다. 덤으로 위젯이 기기 언어가
 * 아니라 앱에서 고른 언어를 따라간다.
 *
 * 잠긴 메모는 여기까지 오지 않는다. 위젯은 잠금 화면에도 뜨므로,
 * 거르는 일은 넘기기 전에 끝나 있어야 한다(HANDOVER 8-3절).
 */
class SkyblueWidgetProvider : HomeWidgetProvider() {

    private val rowIds = intArrayOf(R.id.row0, R.id.row1, R.id.row2, R.id.row3, R.id.row4)
    private val titleIds = intArrayOf(R.id.t0, R.id.t1, R.id.t2, R.id.t3, R.id.t4)
    private val previewIds = intArrayOf(R.id.p0, R.id.p1, R.id.p2, R.id.p3, R.id.p4)
    private val dividerIds = intArrayOf(R.id.d0, R.id.d1, R.id.d2, R.id.d3, R.id.d4)

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val raw = widgetData.getString("feed", null)
        var head = context.getString(R.string.app_name)
        var empty = ""
        val ids = ArrayList<String>()
        val titles = ArrayList<String>()
        val previews = ArrayList<String>()

        if (raw != null) {
            try {
                val j = JSONObject(raw)
                // 판 번호. 앱을 지웠다 깔아도 위젯은 옛 글을 들고 있을 수
                // 있다. 모르는 판이면 아무것도 안 그리는 편이 낫다.
                if (j.optInt("v", 0) == 1) {
                    head = j.optString("title", head)
                    empty = j.optString("empty", "")
                    val arr = j.optJSONArray("items")
                    if (arr != null) {
                        for (i in 0 until arr.length()) {
                            val it = arr.optJSONObject(i) ?: continue
                            ids.add(it.optString("id", ""))
                            titles.add(it.optString("title", ""))
                            previews.add(it.optString("preview", ""))
                        }
                    }
                }
            } catch (_: Exception) {
                // 글이 깨졌으면 빈 위젯. 죽지는 않는다.
            }
        }

        for (id in appWidgetIds) {
            val v = RemoteViews(context.packageName, R.layout.widget_skyblue)
            v.setTextViewText(R.id.w_title, head)

            val shown = if (ids.size > rowIds.size) rowIds.size else ids.size
            v.setViewVisibility(R.id.w_empty, if (shown == 0) View.VISIBLE else View.GONE)
            v.setTextViewText(R.id.w_empty, empty)

            for (i in rowIds.indices) {
                if (i < shown) {
                    v.setViewVisibility(rowIds[i], View.VISIBLE)
                    // 첫 줄 위에는 선을 긋지 않는다. 머리글과 붙어 버린다.
                    v.setViewVisibility(dividerIds[i], if (i == 0) View.GONE else View.VISIBLE)
                    v.setTextViewText(titleIds[i], titles[i])
                    val p = previews[i]
                    v.setTextViewText(previewIds[i], p)
                    v.setViewVisibility(previewIds[i], if (p.isEmpty()) View.GONE else View.VISIBLE)
                    v.setOnClickPendingIntent(
                        rowIds[i],
                        HomeWidgetLaunchIntent.getActivity(
                            context,
                            MainActivity::class.java,
                            Uri.parse("skybluenote://note?id=" + Uri.encode(ids[i]))
                        )
                    )
                } else {
                    v.setViewVisibility(rowIds[i], View.GONE)
                    v.setViewVisibility(dividerIds[i], View.GONE)
                }
            }

            v.setOnClickPendingIntent(
                R.id.w_title,
                HomeWidgetLaunchIntent.getActivity(
                    context, MainActivity::class.java, Uri.parse("skybluenote://home")
                )
            )
            v.setOnClickPendingIntent(
                R.id.w_new,
                HomeWidgetLaunchIntent.getActivity(
                    context, MainActivity::class.java, Uri.parse("skybluenote://new")
                )
            )

            appWidgetManager.updateAppWidget(id, v)
        }
    }
}
