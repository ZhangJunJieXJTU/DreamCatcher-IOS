import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DreamItem.date, order: .reverse) private var dreams: [DreamItem]
    
    @State private var selectedDate: Date = Date()
    
    // 生成日历数据
    private var calendarDays: [Date?] {
        let calendar = Calendar.current
        let interval = calendar.dateInterval(of: .month, for: selectedDate)!
        let firstDay = interval.start
        
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let daysInMonth = calendar.range(of: .day, in: .month, for: selectedDate)!.count
        
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }
        return days
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 日历头部
                HStack {
                    Text(selectedDate.formatted(.dateTime.month(.wide).year()))
                        .font(.title2)
                        .bold()
                    Spacer()
                    HStack(spacing: 20) {
                        Button(action: { changeMonth(by: -1) }) {
                            Image(systemName: "chevron.left")
                        }
                        Button(action: { changeMonth(by: 1) }) {
                            Image(systemName: "chevron.right")
                        }
                    }
                    .foregroundColor(.primary)
                }
                .padding()
                
                // 星期表头
                HStack {
                    ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                // 日历网格
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 15) {
                    ForEach(0..<calendarDays.count, id: \.self) { index in
                        if let date = calendarDays[index] {
                            DayCell(
                                date: date,
                                isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                                hasEvent: hasDream(on: date)
                            )
                            .onTapGesture {
                                selectedDate = date
                            }
                        } else {
                            Color.clear.frame(height: 30)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
                
                // 选中日期的梦境列表
                ZStack {
                    Color(UIColor.secondarySystemBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                        .ignoresSafeArea(edges: .bottom)
                    
                    VStack(alignment: .leading) {
                        Text(selectedDate.formatted(date: .abbreviated, time: .omitted) + " 的梦境")
                            .font(.headline)
                            .padding(.top, 24)
                            .padding(.horizontal)
                        
                        let dayDreams = dreams.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
                        
                        if dayDreams.isEmpty {
                            VStack {
                                Spacer()
                                Image(systemName: "moon.zzz")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                                    .padding(.bottom, 8)
                                Text("暂无梦境记录")
                                    .foregroundColor(.gray)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                        } else {
                            List {
                                ForEach(dayDreams) { dream in
                                    DreamRow(dream: dream)
                                        .listRowSeparator(.hidden)
                                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                        .listRowBackground(Color.clear)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            selectedDream = dream
                                        }
                                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                deleteDream(dream)
                                            } label: {
                                                Label("删除", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                            .listStyle(.plain)
                            .scrollContentBackground(.hidden)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedDream) { dream in
                DreamResultView(
                    dreamItem: dream,
                    onSave: nil,
                    onShare: {}
                )
            }
        }
    }
    
    @State private var selectedDream: DreamItem?
    
    private func deleteDream(_ dream: DreamItem) {
        withAnimation {
            modelContext.delete(dream)
        }
    }
    
    private func changeMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: selectedDate) {
            selectedDate = newDate
        }
    }
    
    private func hasDream(on date: Date) -> Bool {
        return dreams.contains { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let hasEvent: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(Color.purple)
                        .frame(width: 32, height: 32)
                        .shadow(color: .purple.opacity(0.3), radius: 4)
                }
                
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 14))
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            
            Circle()
                .fill(hasEvent ? Color.purple : Color.clear)
                .frame(width: 4, height: 4)
        }
        .frame(height: 40)
    }
}

struct DreamRow: View {
    let dream: DreamItem
    
    var body: some View {
        HStack(spacing: 16) {
            // 缩略图
            UniversalImageView(urlString: dream.imageUrl)
                .frame(width: 60, height: 60)
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(dream.originalText) // 实际可以使用 summary 或 title
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(dream.interpretation)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    CalendarView()
        .modelContainer(for: DreamItem.self, inMemory: true)
}
