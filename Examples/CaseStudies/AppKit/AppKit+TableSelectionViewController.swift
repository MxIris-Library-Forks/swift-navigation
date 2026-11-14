#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
import AppKitNavigation

class TableSelectionViewController: XiblessViewController<NSView>, AppKitCaseStudy {
  let caseStudyTitle = "Table, outline and collection selection"
  let readMe = """
  A table or an outline binds its selected row to the identifier of the selected item, and an \
  outline binds the items it has expanded to a set of identifiers. The model holds identifiers \
  rather than rows, so it does not have to know how the rows are laid out.

  The table uses a diffable data source, which the binding asks for rows directly. The outline \
  uses a data source of its own and gives the binding its row lookups. The buttons change the \
  model; clicking in the table or the outline changes it too.

  A collection view binds the items it has selected to a set of identifiers. Click, ⌘-click, \
  drag across the colors or choose Select All, and the model follows.
  """
  @UIBindable var model = Model()
  private let tableView = NSTableView()
  private let outlineView = NSOutlineView()
  private let outlineDataSource = PantryOutlineDataSource()
  private var tableDataSource: NSTableViewDiffableDataSource<Int, String>?
  private let collectionView = NSCollectionView()
  private var collectionDataSource: NSCollectionViewDiffableDataSource<Int, String>?

  override func viewDidLoad() {
    super.viewDidLoad()

    // MARK: Table

    let tableColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Planet"))
    tableColumn.title = "Planet"
    tableView.addTableColumn(tableColumn)
    let tableDataSource = NSTableViewDiffableDataSource<Int, String>(tableView: tableView) {
      _, _, _, planet in
      NSTextField(labelWithString: planet)
    }
    var snapshot = NSDiffableDataSourceSnapshot<Int, String>()
    snapshot.appendSections([0])
    snapshot.appendItems(["Mercury", "Venus", "Earth", "Mars", "Jupiter"])
    tableDataSource.apply(snapshot, animatingDifferences: false)
    self.tableDataSource = tableDataSource
    tableView.bind(selection: $model.selectedPlanet, dataSource: tableDataSource)

    // MARK: Outline

    // NB: Captured weakly below: the outline keeps its bindings, and the bindings keep these
    //     closures.
    let outlineView = self.outlineView
    let outlineDataSource = self.outlineDataSource
    let outlineColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Item"))
    outlineColumn.title = "Pantry"
    outlineView.addTableColumn(outlineColumn)
    outlineView.outlineTableColumn = outlineColumn
    outlineView.dataSource = outlineDataSource
    outlineView.delegate = outlineDataSource
    outlineView.bind(
      selection: $model.selectedPantryItem,
      row: { [weak outlineView, weak outlineDataSource] name in
        guard let outlineView, let node = outlineDataSource?.node(named: name) else { return nil }
        return outlineView.row(forItem: node)
      },
      itemIdentifier: { [weak outlineView] row in
        (outlineView?.item(atRow: row) as? PantryNode)?.name
      }
    )
    outlineView.bind(
      expandedItems: $model.expandedPantryGroups,
      itemIdentifier: { [weak outlineView] row in
        (outlineView?.item(atRow: row) as? PantryNode)?.name
      }
    )

    // MARK: Collection

    let layout = NSCollectionViewFlowLayout()
    layout.itemSize = NSSize(width: 70, height: 28)
    layout.minimumInteritemSpacing = 6
    layout.minimumLineSpacing = 6
    collectionView.collectionViewLayout = layout
    collectionView.isSelectable = true
    collectionView.allowsMultipleSelection = true
    collectionView.register(ColorItem.self, forItemWithIdentifier: ColorItem.identifier)
    let collectionDataSource = NSCollectionViewDiffableDataSource<Int, String>(
      collectionView: collectionView
    ) { collectionView, indexPath, colorName in
      let item = collectionView.makeItem(withIdentifier: ColorItem.identifier, for: indexPath)
      item.textField?.stringValue = colorName
      return item
    }
    var colorSnapshot = NSDiffableDataSourceSnapshot<Int, String>()
    colorSnapshot.appendSections([0])
    colorSnapshot.appendItems(ColorItem.colorNames)
    collectionDataSource.apply(colorSnapshot, animatingDifferences: false)
    self.collectionDataSource = collectionDataSource
    collectionView.bind(selection: $model.selectedColors, dataSource: collectionDataSource)
    collectionView.backgroundColors = [.clear]
    let collectionScrollView = NSScrollView()
    collectionScrollView.documentView = collectionView
    collectionScrollView.drawsBackground = false
    collectionScrollView.heightAnchor.constraint(equalToConstant: 64).isActive = true

    let planetLabel = makeValueLabel()
    let pantryItemLabel = makeValueLabel()
    let expandedGroupsLabel = makeValueLabel()
    let colorsLabel = makeValueLabel()

    addForm(
      [
        FormSection(
          "Table",
          footer: "The table binds its selected row to the name of the planet in it.",
          rows: [
            FormRow(content: Self.scrollView(containing: tableView, height: 150), insets: NSEdgeInsets(top: 6, left: 0, bottom: 6, right: 0)),
            FormRow(
              "Selection",
              accessories: [
                planetLabel,
                makeButton("Select Mars") { [weak self] in
                  self?.model.selectedPlanet = "Mars"
                },
                makeButton("Clear") { [weak self] in
                  self?.model.selectedPlanet = nil
                },
              ]
            ),
          ]
        ),
        FormSection(
          "Outline",
          footer: "The outline binds its selected row to the name of the item in it, and the groups it has expanded to a set of names.",
          rows: [
            FormRow(content: Self.scrollView(containing: outlineView, height: 170), insets: NSEdgeInsets(top: 6, left: 0, bottom: 6, right: 0)),
            FormRow(
              "Selection",
              accessories: [
                pantryItemLabel,
                makeButton("Select Cherries") { [weak self] in
                  // NB: Expanded too, since a row only exists while its group is expanded.
                  self?.model.expandedPantryGroups.insert("Fruit")
                  self?.model.selectedPantryItem = "Cherries"
                },
              ]
            ),
            FormRow(
              "Expanded groups",
              accessories: [
                expandedGroupsLabel,
                makeButton("Expand All") { [weak self] in
                  self?.model.expandedPantryGroups = Set(PantryOutlineDataSource.groupNames)
                },
                makeButton("Collapse All") { [weak self] in
                  self?.model.expandedPantryGroups = []
                },
              ]
            ),
          ]
        ),
        FormSection(
          "Collection",
          footer: "Click, ⌘-click, drag across the colors or choose Select All, and the model follows.",
          rows: [
            FormRow(content: collectionScrollView),
            FormRow(
              "Selection",
              accessories: [
                colorsLabel,
                makeButton("Select the warm colors") { [weak self] in
                  self?.model.selectedColors = ["Red", "Orange", "Yellow"]
                },
                makeButton("Clear") { [weak self] in
                  self?.model.selectedColors = []
                },
              ]
            ),
          ]
        ),
      ],
      to: view
    )

    observe { [unowned self] in
      planetLabel.stringValue = model.selectedPlanet ?? "None"
      pantryItemLabel.stringValue = model.selectedPantryItem ?? "None"
      expandedGroupsLabel.stringValue =
        model.expandedPantryGroups.isEmpty ? "None" : model.expandedPantryGroups.sorted().joined(separator: ", ")
      colorsLabel.stringValue =
        model.selectedColors.isEmpty
        ? "None" : ColorItem.colorNames.filter(model.selectedColors.contains).joined(separator: ", ")
    }
  }

  /// A scroll view, as tall as `height`, showing `tableView` without a header.
  private static func scrollView(containing tableView: NSTableView, height: CGFloat) -> NSScrollView {
    tableView.headerView = nil
    tableView.style = .inset
    tableView.backgroundColor = .clear
    let scrollView = NSScrollView()
    scrollView.documentView = tableView
    scrollView.hasVerticalScroller = true
    scrollView.autohidesScrollers = true
    scrollView.drawsBackground = false
    scrollView.heightAnchor.constraint(equalToConstant: height).isActive = true
    return scrollView
  }

  @Observable
  class Model {
    var selectedPlanet: String?
    var selectedPantryItem: String?
    var expandedPantryGroups: Set<String> = ["Vegetables"]
    var selectedColors: Set<String> = ["Blue"]
  }
}

/// An item in the collection: the name of a color, highlighted while it is selected.
private final class ColorItem: NSCollectionViewItem {
  static let identifier = NSUserInterfaceItemIdentifier("ColorItem")
  static let colorNames = ["Red", "Orange", "Yellow", "Green", "Blue", "Purple"]

  override func loadView() {
    let label = NSTextField(labelWithString: "")
    label.alignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    let container = NSView()
    container.wantsLayer = true
    container.layer?.cornerRadius = 6
    container.layer?.borderWidth = 1
    container.addSubview(label)
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
    ])
    view = container
    textField = label
    updateAppearance()
  }

  override var isSelected: Bool {
    didSet { updateAppearance() }
  }

  private func updateAppearance() {
    view.layer?.backgroundColor = (isSelected ? NSColor.controlAccentColor : NSColor.clear).cgColor
    view.layer?.borderColor = NSColor.separatorColor.cgColor
    textField?.textColor = isSelected ? .white : .labelColor
  }
}

/// An item in the outline: a group of the pantry, or something in it.
private final class PantryNode {
  let name: String
  let children: [PantryNode]

  init(_ name: String, children: [PantryNode] = []) {
    self.name = name
    self.children = children
  }
}

/// The outline's data: a fixed tree of groups and the items in them.
@MainActor
private final class PantryOutlineDataSource: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate {
  static let groupNames = ["Fruit", "Vegetables"]

  private let groups = [
    PantryNode("Fruit", children: [PantryNode("Apples"), PantryNode("Cherries")]),
    PantryNode("Vegetables", children: [PantryNode("Carrots"), PantryNode("Leeks")]),
  ]

  /// The node with the given name, wherever it is in the tree.
  func node(named name: String) -> PantryNode? {
    for group in groups {
      if group.name == name { return group }
      if let child = group.children.first(where: { $0.name == name }) { return child }
    }
    return nil
  }

  func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
    (item as? PantryNode)?.children.count ?? groups.count
  }

  func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
    (item as? PantryNode)?.children[index] ?? groups[index]
  }

  func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
    !((item as? PantryNode)?.children.isEmpty ?? true)
  }

  func outlineView(
    _ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any
  ) -> NSView? {
    NSTextField(labelWithString: (item as? PantryNode)?.name ?? "")
  }
}

#Preview {
  TableSelectionViewController()
}
#endif
