import WidgetKit
import SwiftUI

@main
struct FitTrackerWidgetBundle: WidgetBundle {
    var body: some Widget {
        TodayProgressWidget()
        WeekChartWidget()
        HourlyActivityWidget()
        WeeklyTotalsWidget()
    }
}
