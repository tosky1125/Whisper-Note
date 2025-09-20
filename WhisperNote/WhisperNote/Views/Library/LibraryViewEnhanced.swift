import SwiftUI

struct LibraryViewEnhanced: View {
    @StateObject private var viewModel = LibraryViewModel()
    @State private var selectedRecording: Recording?
    @State private var showingDeleteAlert = false
    @State private var recordingToDelete: Recording?
    @State private var showingBatchDeleteAlert = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and Filter Bar
                if !viewModel.isSelectionMode {
                    VStack(spacing: 0) {
                        // Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Search recordings...", text: $viewModel.searchText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: viewModel.searchText) { newValue in
                                    viewModel.updateSearchText(newValue)
                                }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)

                        // Filter Chips
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                FilterChip(title: "All", isSelected: viewModel.filterStatus == nil) {
                                    viewModel.updateFilterStatus(nil)
                                }

                                FilterChip(title: "Pending", isSelected: viewModel.filterStatus == .pending) {
                                    viewModel.updateFilterStatus(.pending)
                                }

                                FilterChip(title: "Completed", isSelected: viewModel.filterStatus == .completed) {
                                    viewModel.updateFilterStatus(.completed)
                                }

                                FilterChip(title: "Failed", isSelected: viewModel.filterStatus == .failed) {
                                    viewModel.updateFilterStatus(.failed)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.bottom, 8)
                    }
                    .background(Color(.systemBackground))
                    Divider()
                }

                // Selection Mode Bar
                if viewModel.isSelectionMode {
                    HStack {
                        Button("Cancel") {
                            viewModel.toggleSelectionMode()
                        }

                        Spacer()

                        Text("\(viewModel.selectedRecordings.count) selected")
                            .font(.subheadline)

                        Spacer()

                        Menu {
                            Button {
                                viewModel.selectAll()
                            } label: {
                                Label("Select All", systemImage: "checkmark.circle")
                            }

                            Button {
                                viewModel.deselectAll()
                            } label: {
                                Label("Deselect All", systemImage: "circle")
                            }
                        } label: {
                            Text("Select")
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                }

                List {
                    if viewModel.filteredRecordings.isEmpty {
                        EmptyLibraryView()
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets())
                    } else {
                        ForEach(viewModel.filteredRecordings) { recording in
                            HStack {
                                if viewModel.isSelectionMode {
                                    Image(systemName: viewModel.selectedRecordings.contains(recording.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(.blue)
                                        .onTapGesture {
                                            viewModel.toggleSelection(for: recording)
                                        }
                                }

                                RecordingRowView(recording: recording)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if viewModel.isSelectionMode {
                                    viewModel.toggleSelection(for: recording)
                                } else {
                                    selectedRecording = recording
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                if !viewModel.isSelectionMode {
                                    Button(role: .destructive) {
                                        recordingToDelete = recording
                                        showingDeleteAlert = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }

                                    Button {
                                        viewModel.shareRecording(recording, audioOnly: true)
                                    } label: {
                                        Label("Share", systemImage: "square.and.arrow.up")
                                    }
                                    .tint(.blue)
                                }
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                if !viewModel.isSelectionMode && recording.transcriptionStatus == .pending {
                                    Button {
                                        viewModel.transcribeRecording(recording)
                                    } label: {
                                        Label("Transcribe", systemImage: "text.viewfinder")
                                    }
                                    .tint(.orange)
                                }
                            }
                        }
                    }
                }
                .refreshable {
                    await viewModel.refreshRecordings()
                }
            }
            .navigationTitle(viewModel.isSelectionMode ? "Select Recordings" : "Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !viewModel.isSelectionMode {
                        Button {
                            viewModel.toggleSelectionMode()
                        } label: {
                            Text("Select")
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isSelectionMode {
                        Menu {
                            Button(role: .destructive) {
                                showingBatchDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .disabled(viewModel.selectedRecordings.isEmpty)

                            Button {
                                viewModel.transcribeSelectedRecordings()
                            } label: {
                                Label("Transcribe", systemImage: "text.viewfinder")
                            }
                            .disabled(viewModel.selectedRecordings.isEmpty)
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    } else {
                        Menu {
                            Button {
                                viewModel.sortBy(.date)
                            } label: {
                                Label("Sort by Date", systemImage: "calendar")
                            }

                            Button {
                                viewModel.sortBy(.duration)
                            } label: {
                                Label("Sort by Duration", systemImage: "clock")
                            }

                            Button {
                                viewModel.sortBy(.size)
                            } label: {
                                Label("Sort by Size", systemImage: "doc")
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                        }
                    }
                }
            }
        }
        .alert("Delete Selected Recordings", isPresented: $showingBatchDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteSelectedRecordings()
            }
        } message: {
            Text("Are you sure you want to delete \(viewModel.selectedRecordings.count) recording(s)? This action cannot be undone.")
        }
        .alert("Delete Recording", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let recording = recordingToDelete {
                    viewModel.deleteRecording(recording)
                }
            }
        } message: {
            Text("Are you sure you want to delete this recording? This action cannot be undone.")
        }
        .sheet(item: $selectedRecording) { recording in
            RecordingDetailView(recording: recording)
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(15)
        }
    }
}

#Preview {
    LibraryViewEnhanced()
}