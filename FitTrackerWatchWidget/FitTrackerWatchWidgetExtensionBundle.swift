//
//  FitTrackerWatchWidgetExtensionBundle.swift
//  FitTrackerWatchWidgetExtension
//
//  Created by Michael Förg on 07.03.26.
//

import WidgetKit
import SwiftUI

@main
struct FitTrackerWatchWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        FitChallengeRectangularWidget()
        FitChallengeWeekChartWidget()
        FitChallengeCircularWidget()
        FitChallengeCornerWidget()
        FitChallengeInlineWidget()
    }
}
