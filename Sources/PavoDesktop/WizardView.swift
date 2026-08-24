import SwiftUI

struct WizardView: View {
    @EnvironmentObject private var desk: Desk
    let rec: Recording
    @State private var addingFor: String?
    @State private var newName = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if desk.step == 0 {
                typeStep
            } else if desk.packId == "omf" && desk.step == 1 {
                peopleStep
            } else {
                tagsStep
            }
            actions
        }
    }

    private var typeStep: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What is this?").font(.headline)
            Text("Exclusive. This choice reweights people and tags next.")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                ForEach(desk.packs) { pack in
                    Button {
                        desk.packId = pack.id
                    } label: {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(pack.name)
                            Text(pack.id).font(.caption.monospaced()).foregroundStyle(.secondary)
                            HStack {
                                Text(desk.packId == pack.id ? "Using this" : "Estimate")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(pack.pct)%").font(.title3.monospacedDigit())
                            }
                            GeometryReader { geo in
                                Capsule().fill(.quaternary)
                                Capsule().fill(.tint).frame(width: geo.size.width * CGFloat(pack.pct) / 100)
                            }
                            .frame(height: 4)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
                        .background(desk.packId == pack.id ? Color.accentColor.opacity(0.12) : Color.primary.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(desk.packId == pack.id ? Color.accentColor : Color.primary.opacity(0.12), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var peopleStep: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Who was on this call?").font(.headline)
            Text("Every detected speaker needs a contact. Ranked by print, name, call context. Ordered by %.")
                .font(.caption)
                .foregroundStyle(.secondary)
            VStack(spacing: 0) {
                ForEach(desk.selectedSpans) { span in
                    HStack(alignment: .center, spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(span.label)
                            Text("detected · \(clock(span.start))–\(clock(span.end))")
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Picker("Contact", selection: Binding(
                            get: { span.assignedId },
                            set: { id in
                                if id == "__new__" {
                                    addingFor = span.id
                                } else {
                                    desk.assign(spanId: span.id, personId: id)
                                }
                            }
                        )) {
                            ForEach(span.odds) { o in
                                Text("\(o.name) \(o.pct)%").tag(o.personId)
                            }
                            Text("Add person…").tag("__new__")
                        }
                        .labelsHidden()
                        .frame(minWidth: 200)
                    }
                    .padding(.vertical, 10)
                    Divider()
                }
            }
            .padding(.horizontal, 4)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.12)))

            if let spanId = addingFor {
                HStack {
                    TextField("Full name", text: $newName)
                        .textFieldStyle(.roundedBorder)
                    Button("Add & assign") {
                        desk.addPerson(named: newName, to: spanId)
                        newName = ""
                        addingFor = nil
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
    }

    private var tagsStep: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Which tags?").font(.headline)
            Text("Multi — each fill is independent.").font(.caption).foregroundStyle(.secondary)
            let options = ["work", "product", "hiring", "format", "personal", "notes", "errands"]
            FlowTags(tags: options, selected: $desk.tags)
        }
    }

    private var actions: some View {
        HStack {
            if desk.step > 0 {
                Button("Back") { desk.step -= 1 }
            }
            if desk.step < desk.stepsForPack - 1 {
                Button("Continue") { desk.step += 1 }
                    .keyboardShortcut(.defaultAction)
            } else {
                Button("Land pack") { desk.land() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(.top, 4)
    }
}

struct FlowTags: View {
    let tags: [String]
    @Binding var selected: Set<String>

    var body: some View {
        HStack {
            ForEach(tags, id: \.self) { tag in
                Toggle(tag, isOn: Binding(
                    get: { selected.contains(tag) },
                    set: { on in
                        if on { selected.insert(tag) } else { selected.remove(tag) }
                    }
                ))
                .toggleStyle(.button)
            }
        }
    }
}
