//
//  HorizontalTimelineView.swift
//  CustomTimelinePicker
//
//  Created by Ali Tamoor on 19/06/2024.
//

import SwiftUI
import AudioToolbox

struct HorizontalTimelineView: View {
    let rangeStart: Int = 1
    let rangeEnd: Int = 23
    let quartersPerHour: Int = 3  // 3 quarter markers per hour (every 15 minutes)
    let mainLineHeight: CGFloat = 35
    let quarterLineHeight: CGFloat = 20
    let cursorHeight: CGFloat = 45  // Height of the cursor line
    let lineSpacing: CGFloat = 0   // Spacing between each line
    let blockWidth: Double = 12    // Width for each line
    
    @State private var scrollOffset: CGFloat = 0
    @State private var cursorValue: String = "1:00"
    @State private var scrollToIndex: Double?
    @State private var isSnappingEnabled: Bool = true
    
    init() {
        UIScrollView.appearance().bounces = false
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .center) {
                ScrollViewReader { scrollViewProxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        ZStack {
                            ScrollViewOffsetReader(onScrollingStarted: {
                                
                            }, onScrollingFinished: {
                                if isSnappingEnabled { snapToNearestLine() }
                            })
                            HStack(spacing: 0) {
                                ForEach(rangeStart...rangeEnd, id: \.self) { hour in
                                    HStack(alignment: .top, spacing: self.lineSpacing) {
                                        VStack(alignment: .leading, spacing: 0) {
                                            LineView(lineHeight: mainLineHeight, blockWidth: blockWidth, color: .black, id: Double(hour))
                                        }
                                        
                                        ForEach(1...self.quartersPerHour, id: \.self) { quarter in
                                            LineView(lineHeight: quarterLineHeight, blockWidth: blockWidth, color: .gray, id: Double(hour) + 0.1 * ceil(Double(quarter)))
                                        }
                                        
                                        if hour == 23 {
                                            LineView(lineHeight: mainLineHeight, blockWidth: blockWidth, color: .black, id: Double(hour + 1))
                                        }
                                    }
                                }
                            }
                            .padding(.trailing, geometry.size.width - blockWidth)
                            .background(
                                // To detect the movement in the scrollview
                                GeometryReader { proxy in
                                    Color.clear
                                        .onAppear {
                                            self.scrollOffset = proxy.frame(in: .named("scroll")).minX
                                        }
                                        .onChange(of: proxy.frame(in: .named("scroll")).minX) { newValue in
                                            updateCursorValue(for: newValue, currentPositon: geometry.size.width / 2)
                                        }
                                }
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .offset(x: (geometry.size.width) / 2, y: 0)
                        }
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                isSnappingEnabled = true
                            }
                    )
                    .onChange(of: scrollToIndex) { index in
                        if let index = index {
                            withAnimation {
                                scrollViewProxy.scrollTo(index, anchor: .top)
                            }
                        }
                    }
                    .overlay(
                        // Marker above the timeline
                        VStack(spacing: 0) {
                            Circle()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.blue)
                                .overlay {
                                    VStack(spacing: 0) {
                                        Text("\(cursorValue)h")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(Color.white)
                                    }
                                }
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: 2, height: self.cursorHeight)
                                .fixedSize()
                        }
                            .offset(x: 0, y: -mainLineHeight)
                    )
                }
            }
            .padding(.top, geometry.safeAreaInsets.top + 10)
            .coordinateSpace(name: "scroll")
        }
    }
    
    func updateCursorValue(for offSet: CGFloat, currentPositon: CGFloat) {
        self.scrollOffset = offSet - currentPositon
        let offset = -self.scrollOffset
        let totalMinutes = 60 + Int(offset / blockWidth) * 15
        let minutes = totalMinutes % 60
        let hours = totalMinutes / 60
        self.cursorValue = String(format: "%01d:%02d", hours, minutes)
    }
    
    func snapToNearestLine() {
        let val = (((-self.scrollOffset) / 4) / blockWidth) + 1
        let finally = roundToNearestTenth(val)
        print(finally)
        scrollToIndex = finally
        isSnappingEnabled = false
        
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
        AudioServicesPlayAlertSound(1157)
    }
    
    func roundToNearestTenth(_ value: Double) -> Double {
        let integerPart = Double(Int(value))
        let decimalPart = value - integerPart
        
        switch decimalPart {
        case 0.0..<0.375:
            return integerPart + 0.1
        case 0.375..<0.625:
            return integerPart + 0.2
        case 0.625..<0.875:
            return integerPart + 0.3
        case 0.875..<1.0:
            return integerPart + 1.0
        default:
            return value
        }
    }
}

struct HorizontalTimelineView_Previews: PreviewProvider {
    static var previews: some View {
        HorizontalTimelineView()
    }
}

// MARK: - LineView
struct LineView: View {
    var lineHeight: Double
    var blockWidth: Double
    var color: Color
    var id: Double
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Rectangle()
                .fill(color)
                .frame(width: 1, height: lineHeight)
                .id(id)
            Spacer()
        }
        .frame(width: blockWidth)
    }
}
