
import UIKit
import PlaygroundSupport

class MainViewController: UIViewController {
    // MARK: UI Elements

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Etch"
        label.font = .preferredFont(forTextStyle: .largeTitle)

        return label
    }()

    private lazy var gridView: GridView = GridView(gridArray: gridArray)
    private let controlView: ControlView = ControlView(frame: .zero)
    private let colourPickerView: ColourPickerView = ColourPickerView()

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.distribution = .equalSpacing

        return stackView
    }()

    // MARK: Properties

    private let gridDimension: Int = 32
    private var gridArray: [[UIColor]] {
        Array(repeating: Array(repeating: Colours.brandWhite, count: gridDimension), count: gridDimension)
    }

    // MARK: Life Cycle Methods

    override func loadView() {
        let view = UIView()
        view.backgroundColor = Colours.brandPink

        self.view = view
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        buildUI()
        applyConstraints()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        gridView.setUp()
    }

    // MARK: Methods

    private func buildUI() {
        controlView.delegate = self
        colourPickerView.colourDelegate = self

        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(gridView)
        stackView.addArrangedSubview(controlView)
        stackView.addArrangedSubview(colourPickerView)

        view.addSubview(stackView)
    }

    private func applyConstraints() {
        stackView.activateConstraints([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 16)
        ])

        gridView.activateConstraints([
            gridView.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            gridView.heightAnchor.constraint(equalTo: gridView.widthAnchor)
        ])

        /// Frame height was not being set properly so using constant.
        controlView.activateConstraints([
            controlView.heightAnchor.constraint(equalToConstant: 112)
        ])

        colourPickerView.activateConstraints([
            colourPickerView.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            colourPickerView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
}

// MARK: - MainViewController ControlDelegate

extension MainViewController: ControlDelegate {
    func didPressMoveUp() {
        gridView.moveUp()
    }

    func didPressMoveRight() {
        gridView.moveRight()
    }

    func didPressMoveDown() {
        gridView.moveDown()
    }

    func didPressMoveLeft() {
        gridView.moveLeft()
    }
}

// MARK: - MainViewController ColourPickerDelegate

extension MainViewController: ColourPickerDelegate {
    func didSelectColour(_ colour: UIColor) {
        controlView.setColour(to: colour)
        gridView.selectedColour = colour
    }
}

// MARK: - GridView

class GridView: UICollectionView {
    // MARK: Properties

    private let flowLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        return layout
    }()

    private let cellIdentifier = String(describing: GridCell.self)
    private var currentPosition: IndexPath?
    private var gridArray: [[UIColor]]
    var selectedColour: UIColor = Colours.black {
        didSet {
            /// Change the colour of cell you are currently on.
            guard let currentPos = currentPosition else { return }
            selectCells([currentPos])
        }
    }

    // MARK: Initialization

    init(gridArray: [[UIColor]]) {
        self.gridArray = gridArray
        super.init(frame: .zero, collectionViewLayout: flowLayout)

        register(GridCell.self, forCellWithReuseIdentifier: cellIdentifier)
        dataSource = self
        delegate = self
        collectionViewLayout = flowLayout
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public Methods

    /// Call this method when the view has loaded to get the correct frame when using constraints.
    func setUp() {
        let width = frame.width / CGFloat(gridArray.count)
        let height = frame.height / CGFloat(gridArray.count)

        flowLayout.itemSize = CGSize(width: width, height: height)
    }

    func moveUp() {
        guard let currentPos = currentPosition else { return }

        selectCells([currentPos.above])
    }

    func moveRight() {
        guard let currentPos = currentPosition else { return }

        selectCells([currentPos.right])
    }

    func moveDown() {
        guard let currentPos = currentPosition else { return }

        selectCells([currentPos.below])
    }

    func moveLeft() {
        guard let currentPos = currentPosition else { return }

        selectCells([currentPos.left])
    }

    // MARK: Private Methods

    private func isSurroundingIndex(_ indexPath: IndexPath) -> Bool {
        guard let currentPos = currentPosition else { return false }

        let isAbove: Bool = indexPath == currentPos.above
        let isRight: Bool = indexPath == currentPos.right
        let isBelow: Bool = indexPath == currentPos.below
        let isLeft: Bool = indexPath == currentPos.left

        return isAbove || isRight || isBelow || isLeft
    }

    private func isValidIndex(_ indexPath: IndexPath) -> Bool {
        let topValid: Bool = indexPath.section >= 0
        let rightValid: Bool = indexPath.row < gridArray.count
        let bottomValid: Bool = indexPath.section < gridArray.count
        let leftValid: Bool = indexPath.row >= 0

        return topValid && rightValid && bottomValid && leftValid
    }

    private func selectCells(_ indexPaths: [IndexPath]) {
        guard let currentPos = currentPosition else { return }

        /// Only use indexPaths within bounds of grid
        let validIndexPaths: [IndexPath] = indexPaths.filter({ isValidIndex($0) })

        for indexPath in validIndexPaths {
            gridArray[indexPath.row][indexPath.section] = selectedColour
        }
        reloadItems(at: validIndexPaths)

        guard let lastIndex = validIndexPaths.last else { return }

        if let currentCell = cellForItem(at: currentPos) as? GridCell,
           let newCell = cellForItem(at: lastIndex) as? GridCell {
            currentCell.stopBlinking()
            newCell.startBlinking()
        }

        currentPosition = lastIndex
    }
}

// MARK: - GridView Data Source

extension GridView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        gridArray.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        /// Dimensions of 2D array will always be equal so using columns again is sufficient.
        gridArray.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? GridCell {
            cell.backgroundColor = gridArray[indexPath.row][indexPath.section]

            return cell
        }

        return UICollectionViewCell()
    }
}

// MARK: - GridView Delegate

extension GridView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        /// If current position is nil, set it to the tapped cell.
        guard currentPosition != nil else {
            currentPosition = indexPath
            selectCells([indexPath])
            return
        }

        guard isSurroundingIndex(indexPath) else { return }

        selectCells([indexPath])
    }
}

// MARK: - GridCell

class GridCell: UICollectionViewCell {
    // MARK: Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        buildUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public Methods

    func startBlinking() {
        alpha = 0.5
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       options: [.curveEaseInOut, .autoreverse, .repeat, .allowUserInteraction]) {
            self.alpha = 1
        } completion: { _ in
            self.alpha = 0.5
        }
    }

    func stopBlinking() {
        layer.removeAllAnimations()
        alpha = 1
    }

    // MARK: Private Methods

    private func buildUI() {
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.black.cgColor
        layer.cornerRadius = 2
    }
}

// MARK: - ControlButton

class ControlButton: UIButton {
    // MARK: Types

    enum Direction {
        case up, right, down, left

        var symbol: String {
            switch self {
            case .up: return "arrowtriangle.up.fill"
            case .right: return "arrowtriangle.right.fill"
            case .down: return "arrowtriangle.down.fill"
            case .left: return "arrowtriangle.left.fill"
            }
        }
    }

    // MARK: Properties

    private let direction: Direction

    // MARK: Initialization

    init(direction: Direction) {
        self.direction = direction
        super.init(frame: .zero)

        buildUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Methods

    private func buildUI() {
        backgroundColor = Colours.brandSalmon
        layer.cornerRadius = 5
        let image = UIImage(systemName: direction.symbol)
        setImage(image, for: .normal)

        tintColor = Colours.brandBrown
    }
}

// MARK: - ControlDelegate

protocol ControlDelegate: AnyObject {
    func didPressMoveUp()
    func didPressMoveRight()
    func didPressMoveDown()
    func didPressMoveLeft()
}

// MARK: - ControlView

class ControlView: UIView {
    // MARK: UI Elements

    private let upButton: ControlButton = ControlButton(direction: .up)
    private let rightButton: ControlButton = ControlButton(direction: .right)
    private let downButton: ControlButton = ControlButton(direction: .down)
    private let leftButton: ControlButton = ControlButton(direction: .left)

    private let colourView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 5
        view.backgroundColor = Colours.black

        return view
    }()

    private let horizStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.distribution = .fillProportionally
        stackView.translatesAutoresizingMaskIntoConstraints = false

        return stackView
    }()

    private let vertStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false

        return stackView
    }()

    // MARK: Properties

    weak var delegate: ControlDelegate?

    // MARK: Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        buildUI()
        applyConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public Methods

    func setColour(to colour: UIColor) {
        colourView.backgroundColor = colour
    }

    // MARK: Private Methods

    private func buildUI() {
        upButton.addTarget(self, action: #selector(moveUpPressed), for: .touchUpInside)
        rightButton.addTarget(self, action: #selector(moveRightPressed), for: .touchUpInside)
        downButton.addTarget(self, action: #selector(moveDownPressed), for: .touchUpInside)
        leftButton.addTarget(self, action: #selector(moveLeftPressed), for: .touchUpInside)

        vertStackView.addArrangedSubview(upButton)

        horizStackView.addArrangedSubview(leftButton)
        horizStackView.addArrangedSubview(colourView)
        horizStackView.addArrangedSubview(rightButton)

        vertStackView.addArrangedSubview(horizStackView)
        vertStackView.addArrangedSubview(downButton)

        addSubview(vertStackView)
    }

    private func applyConstraints() {
        [upButton, rightButton, downButton, leftButton, colourView].forEach { view in
            view.activateConstraints([
                view.widthAnchor.constraint(equalToConstant: 32),
                view.heightAnchor.constraint(equalToConstant: 32)
            ])
        }
    }

    // MARK: Actions

    @objc
    private func moveUpPressed() {
        delegate?.didPressMoveUp()
    }

    @objc
    private func moveRightPressed() {
        delegate?.didPressMoveRight()
    }

    @objc
    private func moveDownPressed() {
        delegate?.didPressMoveDown()
    }

    @objc
    private func moveLeftPressed() {
        delegate?.didPressMoveLeft()
    }
}

// MARK: - ColourPickerDelegate

protocol ColourPickerDelegate: AnyObject {
    func didSelectColour(_ colour: UIColor)
}

// MARK: - ColourPickerView

class ColourPickerView: UICollectionView {
    // MARK: Properties

    private let flowLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 4
        /// Using just outside 8x scale to show half a cell at end of layout.
        layout.itemSize = CGSize(width: 34, height: 34)
        layout.scrollDirection = .horizontal

        return layout
    }()

    private let cellIdentifier = String(describing: ColourCell.self)
    private let colourArray: [UIColor] = [Colours.black, Colours.blue, Colours.red, Colours.tan,
                                          Colours.darkGreen, Colours.lightGreen, Colours.yellow, Colours.white,
                                          Colours.gray, Colours.cyan, Colours.orange, Colours.brown,
                                          Colours.pink, Colours.violet, Colours.brightGreen, Colours.magenta]
    private var selectedIndex: IndexPath = IndexPath(row: 0, section: 0)

    weak var colourDelegate: ColourPickerDelegate?

    // MARK: Initialization

    init() {
        super.init(frame: .zero, collectionViewLayout: flowLayout)

        register(ColourCell.self, forCellWithReuseIdentifier: cellIdentifier)
        dataSource = self
        delegate = self
        collectionViewLayout = flowLayout
        backgroundColor = .clear
        showsHorizontalScrollIndicator = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - ColourPickerView Data Source

extension ColourPickerView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        colourArray.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? ColourCell {
            cell.backgroundColor = colourArray[indexPath.row]
            cell.layer.borderWidth = indexPath == selectedIndex ? 0 : 4

            return cell
        }

        return UICollectionViewCell()
    }
}

// MARK: - ColourPickerView Delegate

extension ColourPickerView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        colourDelegate?.didSelectColour(colourArray[indexPath.row])
        selectedIndex = indexPath
        reloadItems(at: indexPathsForVisibleItems)
    }
}

// MARK: - ColourCell

class ColourCell: UICollectionViewCell {
    // MARK: Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        buildUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Methods

    private func buildUI() {
        layer.cornerRadius = 5
        layer.borderColor = Colours.brandPink.cgColor
    }
}

// MARK: - Colours

struct Colours {
    /// Brand colours used in UI.
    static let brandWhite: UIColor = UIColor(red: 236 / 255, green: 252 / 255, blue: 246 / 255, alpha: 1)
    static let brandPink: UIColor = UIColor(red: 250 / 255, green: 228 / 255, blue: 230 / 255, alpha: 1)
    static let brandSalmon: UIColor = UIColor(red: 255 / 255, green: 205 / 255, blue: 182 / 255, alpha: 1)
    static let brandBrown: UIColor = UIColor(red: 35 / 255, green: 26 / 255, blue: 19 / 255, alpha: 1)

    /// Colours to use in colour palette.
    static let black: UIColor = UIColor(red: 0 / 255, green: 0 / 255, blue: 0 / 255, alpha: 1)
    static let blue: UIColor = UIColor(red: 0 / 255, green: 0 / 255, blue: 255 / 255, alpha: 1)
    static let red: UIColor = UIColor(red: 255 / 255, green: 0 / 255, blue: 0 / 255, alpha: 1)
    static let tan: UIColor = UIColor(red: 203 / 255, green: 255 / 255, blue: 101 / 255, alpha: 1)
    static let darkGreen: UIColor = UIColor(red: 0 / 255, green: 127 / 255, blue: 0 / 255, alpha: 1)
    static let lightGreen: UIColor = UIColor(red: 0 / 255, green: 255 / 255, blue: 0 / 255, alpha: 1)
    static let yellow: UIColor = UIColor(red: 255 / 255, green: 255 / 255, blue: 0 / 255, alpha: 1)
    static let white: UIColor = UIColor(red: 255 / 255, green: 255 / 255, blue: 255 / 255, alpha: 1)
    static let gray: UIColor = UIColor(red: 127 / 255, green: 127 / 255, blue: 127 / 255, alpha: 1)
    static let cyan: UIColor = UIColor(red: 0 / 255, green: 255 / 255, blue: 255 / 255, alpha: 1)
    static let orange: UIColor = UIColor(red: 255 / 255, green: 159 / 255, blue: 0 / 255, alpha: 1)
    static let brown: UIColor = UIColor(red: 127 / 255, green: 127 / 255, blue: 0 / 255, alpha: 1)
    static let pink: UIColor = UIColor(red: 255 / 255, green: 63 / 255, blue: 255 / 255, alpha: 1)
    static let violet: UIColor = UIColor(red: 127 / 255, green: 127 / 255, blue: 255 / 255, alpha: 1)
    static let brightGreen: UIColor = UIColor(red: 127 / 255, green: 255 / 255, blue: 0 / 255, alpha: 1)
    static let magenta: UIColor = UIColor(red: 255 / 255, green: 0 / 255, blue: 127 / 255, alpha: 1)
}

// MARK: - Utils

extension IndexPath {
    var above: IndexPath {
        IndexPath(row: row, section: section - 1)
    }

    var right: IndexPath {
        IndexPath(row: row + 1, section: section)
    }

    var below: IndexPath {
        IndexPath(row: row, section: section + 1)
    }

    var left: IndexPath {
        IndexPath(row: row - 1, section: section)
    }
}

extension UIView {
    func activateConstraints(_ constraints: [NSLayoutConstraint]) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(constraints)
    }
}

let vc = MainViewController()
PlaygroundPage.current.liveView = vc
