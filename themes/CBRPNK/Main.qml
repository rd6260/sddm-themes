import QtQuick 2.15
import QtQuick.Shapes 1.15

// CBRPNK — bento-card cyberpunk login.
// Black canvas, four flat cards: robot poster · orange console (login) ·
// green session tag · grey clock.
Rectangle {
    id: root
    color: "#000000"

    readonly property real s: height / 768

    // Palette sampled from the inspiration board
    readonly property color ink: "#141414"
    readonly property color red: "#b93d38"
    readonly property color orange: "#e0a15c"
    readonly property color green: "#6c9a6b"
    readonly property color grey: "#9b9b9b"

    readonly property string display: "Archivo Black"
    readonly property string mono: "Space Mono"

    property int sessionIndex: (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property int userIndex: (typeof userModel !== "undefined" && userModel.lastIndex >= 0) ? userModel.lastIndex : 0
    property real ui: 0
    property string errorMessage: ""
    property date now: new Date()

    function pad(n) { return (n < 10 ? "0" : "") + n; }

    // Machine name: greeter-provided -> theme.conf -> /etc/hostname
    property string hostLabel: resolveHost()
    function resolveHost() {
        var h = "";
        if (typeof sddm !== "undefined" && sddm.hostName) h = sddm.hostName;
        if (!h && typeof config !== "undefined" && config.hostName) h = config.hostName;
        if (!h) {
            try {
                var x = new XMLHttpRequest();
                x.open("GET", "file:///etc/hostname", false);
                x.send();
                h = (x.responseText || "").trim();
            } catch (e) {}
        }
        return (h || "LOCALHOST").toUpperCase();
    }

    FontLoader { source: "font/ArchivoBlack-Regular.ttf" }
    FontLoader { source: "font/SpaceMono-Bold.ttf" }
    FontLoader { source: "font/ChakraPetch-SemiBold.ttf" }

    // Helpers for current user / session names
    ListView {
        id: sessionHelper
        model: typeof sessionModel !== "undefined" ? sessionModel : null
        currentIndex: root.sessionIndex
        opacity: 0; width: 1; height: 1; z: -100
        delegate: Item { property string sName: model.name || "" }
    }
    ListView {
        id: userHelper
        model: typeof userModel !== "undefined" ? userModel : null
        currentIndex: root.userIndex
        opacity: 0; width: 1; height: 1; z: -100
        delegate: Item {
            property string uName: model.realName || model.name || ""
            property string uLogin: model.name || ""
        }
    }

    readonly property string userLabel: ((userHelper.currentItem && userHelper.currentItem.uName) ? userHelper.currentItem.uName : (typeof userModel !== "undefined" ? userModel.lastUser : "") || "USER").toUpperCase()
    readonly property string sessionLabel: ((sessionHelper.currentItem && sessionHelper.currentItem.sName) ? sessionHelper.currentItem.sName : "SESSION").toUpperCase()

    Timer { interval: 300; running: true; onTriggered: pwd.forceActiveFocus() }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }

    Connections {
        target: typeof sddm !== "undefined" ? sddm : null
        function onLoginFailed() {
            root.errorMessage = "ACCESS DENIED";
            pwd.text = "";
            shakeAnim.start();
            errTimer.start();
        }
    }
    Timer { id: errTimer; interval: 3000; onTriggered: root.errorMessage = "" }

    Component.onCompleted: {
        fadeAnim.start();
        if (typeof keyboard !== "undefined") keyboard.numLock = true;
    }
    NumberAnimation { id: fadeAnim; target: root; property: "ui"; from: 0; to: 1; duration: 900; easing.type: Easing.OutCubic }

    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: shakeT; property: "x"; to: 12 * s; duration: 50 }
        NumberAnimation { target: shakeT; property: "x"; to: -12 * s; duration: 50 }
        NumberAnimation { target: shakeT; property: "x"; to: 12 * s; duration: 50 }
        NumberAnimation { target: shakeT; property: "x"; to: 0; duration: 50 }
    }

    MouseArea { anchors.fill: parent; z: -1; onClicked: pwd.forceActiveFocus() }

    function login() {
        if (pwd.text !== "") {
            var u = userHelper.currentItem ? userHelper.currentItem.uLogin : userModel.lastUser;
            sddm.login(u, pwd.text, root.sessionIndex);
        }
    }

    // ── Grid geometry ────────────────────────────────────────────────────────
    readonly property real m: 56 * s
    readonly property real gap: 14 * s
    readonly property real r: 26 * s
    readonly property real innerH: height - 2 * m
    readonly property real posterW: Math.min(innerH * 869 / 1810, (width - 2 * m) * 0.32)
    readonly property real rightX: m + posterW + gap
    readonly property real rightW: width - m - rightX
    readonly property real topH: Math.round(innerH * 0.56 - gap / 2)
    readonly property real botH: innerH - topH - gap
    readonly property real halfW: (rightW - gap) / 2

    // ── 01 · Robot poster ────────────────────────────────────────────────────
    Item {
        id: poster
        x: root.m; y: root.m
        width: root.posterW; height: root.innerH
        opacity: root.ui

        Rectangle { anchors.fill: parent; radius: root.r; color: root.red }
        Image {
            anchors.fill: parent
            source: "image.png"
            fillMode: Image.PreserveAspectCrop
            horizontalAlignment: Image.AlignRight
            smooth: true
        }
        // Rounded-corner mask: black frame with a rounded hole
        Shape {
            anchors.fill: parent
            ShapePath {
                fillColor: "#000000"
                strokeColor: "transparent"
                fillRule: ShapePath.OddEvenFill
                startX: 0; startY: 0
                PathLine { x: poster.width; y: 0 }
                PathLine { x: poster.width; y: poster.height }
                PathLine { x: 0; y: poster.height }
                PathLine { x: 0; y: 0 }
                PathMove { x: root.r; y: 0 }
                PathLine { x: poster.width - root.r; y: 0 }
                PathArc { x: poster.width; y: root.r; radiusX: root.r; radiusY: root.r }
                PathLine { x: poster.width; y: poster.height - root.r }
                PathArc { x: poster.width - root.r; y: poster.height; radiusX: root.r; radiusY: root.r }
                PathLine { x: root.r; y: poster.height }
                PathArc { x: 0; y: poster.height - root.r; radiusX: root.r; radiusY: root.r }
                PathLine { x: 0; y: root.r }
                PathArc { x: root.r; y: 0; radiusX: root.r; radiusY: root.r }
            }
        }
    }

    // ── Orange console ───────────────────────────────────────────────────────
    Rectangle {
        id: orangeCard
        x: root.rightX; y: root.m
        width: root.rightW; height: root.topH
        radius: root.r
        color: root.orange
        opacity: root.ui

        readonly property real p: 26 * root.s

        // Wordmark + red dot
        Text {
            id: brand
            x: orangeCard.p; y: orangeCard.p - 4 * root.s
            text: root.hostLabel
            font.family: root.display
            font.pixelSize: 58 * root.s
            font.letterSpacing: -1 * root.s
            color: root.ink
            width: Math.min(implicitWidth, orangeCard.width - 220 * root.s)
            fontSizeMode: Text.HorizontalFit
            minimumPixelSize: 24 * root.s
        }
        Rectangle {
            x: brand.x + brand.paintedWidth + 8 * root.s
            y: brand.y + 4 * root.s
            width: 14 * root.s; height: width; radius: width / 2
            color: root.red
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { to: 0.25; duration: 700 }
                NumberAnimation { to: 1.0; duration: 700 }
            }
        }

        // Bold arrow
        Canvas {
            anchors.right: parent.right; anchors.rightMargin: orangeCard.p
            anchors.top: parent.top; anchors.topMargin: orangeCard.p - 6 * root.s
            width: 76 * root.s; height: width
            onPaint: {
                var c = getContext("2d");
                c.reset();
                c.scale(width / 100, height / 100);
                c.fillStyle = "#141414";
                c.beginPath();
                c.moveTo(100, 0); c.lineTo(34, 0); c.lineTo(56, 22); c.lineTo(0, 78);
                c.lineTo(22, 100); c.lineTo(78, 44); c.lineTo(100, 66);
                c.closePath();
                c.fill();
            }
        }

        // Middle row y
        readonly property real rowY: orangeCard.p + 82 * root.s
        readonly property real rowH: height - rowY - 78 * root.s

        // Gauge box: H M S D
        Rectangle {
            id: gauge
            x: orangeCard.p; y: orangeCard.rowY
            width: 128 * root.s; height: orangeCard.rowH
            color: "transparent"
            border.color: root.ink; border.width: 2 * root.s
            radius: 2 * root.s

            Row {
                anchors.centerIn: parent
                spacing: 6 * root.s
                Repeater {
                    model: [
                        { l: "H", v: root.now.getHours() / 23 },
                        { l: "M", v: root.now.getMinutes() / 59 },
                        { l: "S", v: root.now.getSeconds() / 59 },
                        { l: "D", v: (root.now.getDay() + 1) / 7 }
                    ]
                    delegate: Column {
                        spacing: 6 * root.s
                        Rectangle {
                            width: 20 * root.s
                            height: gauge.height - 52 * root.s
                            color: "transparent"
                            border.color: root.ink; border.width: 2 * root.s
                            Rectangle {
                                anchors.left: parent.left; anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                anchors.margins: 2 * root.s
                                height: Math.max(2 * root.s, (parent.height - 4 * root.s) * modelData.v)
                                color: root.red
                                Behavior on height { NumberAnimation { duration: 300 } }
                            }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.l
                            font.family: root.display
                            font.pixelSize: 14 * root.s
                            color: root.ink
                        }
                    }
                }
            }
        }

        // Login panel
        Rectangle {
            id: loginBox
            x: gauge.x + gauge.width + 18 * root.s
            y: orangeCard.rowY
            width: Math.min(420 * root.s, orangeCard.width - x - 250 * root.s)
            height: orangeCard.rowH
            color: "transparent"
            border.color: root.ink; border.width: 2 * root.s
            radius: 2 * root.s
            transform: Translate { id: shakeT }

            // Title bar
            Item {
                id: lbTitle
                anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                height: 34 * root.s
                Text {
                    anchors.left: parent.left; anchors.leftMargin: 14 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.errorMessage !== "" ? root.errorMessage : "UA 570-B"
                    font.family: root.mono; font.bold: true
                    font.pixelSize: 14 * root.s
                    color: root.errorMessage !== "" ? root.red : root.ink
                }
                Text {
                    anchors.right: parent.right; anchors.rightMargin: 14 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    text: "AUTH"
                    font.family: root.mono; font.bold: true
                    font.pixelSize: 12 * root.s
                    color: root.ink
                }
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 2 * root.s; color: root.ink }
            }

            // Rows
            Column {
                anchors.top: lbTitle.bottom; anchors.bottom: parent.bottom
                anchors.left: parent.left; anchors.right: parent.right
                anchors.margins: 14 * root.s
                spacing: 0

                readonly property real rowH: height / 2

                // USER row (click to cycle)
                Item {
                    width: parent.width; height: parent.rowH
                    Text {
                        id: userLbl
                        anchors.left: parent.left; anchors.top: userBox.top
                        anchors.topMargin: 4 * root.s
                        width: 82 * root.s
                        text: (typeof userModel !== "undefined" && userModel.count > 1) ? "USER ▸" : "USER"
                        font.family: root.mono; font.bold: true
                        font.pixelSize: 11 * root.s
                        color: root.ink
                    }
                    Rectangle {
                        id: userBox
                        anchors.left: userLbl.right; anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: 40 * root.s
                        radius: 3 * root.s
                        color: userMa.containsMouse ? root.ink : "transparent"
                        border.color: root.ink; border.width: 2 * root.s
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Text {
                            anchors.fill: parent; anchors.leftMargin: 12 * root.s; anchors.rightMargin: 12 * root.s
                            verticalAlignment: Text.AlignVCenter
                            text: root.userLabel
                            elide: Text.ElideRight
                            font.family: root.display
                            font.pixelSize: 20 * root.s
                            color: userMa.containsMouse ? root.orange : root.ink
                        }
                        MouseArea {
                            id: userMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (typeof userModel !== "undefined" && userModel.count > 0)
                                    root.userIndex = (root.userIndex + 1) % userModel.count;
                            }
                        }
                    }
                }

                // PASSWORD row
                Item {
                    width: parent.width; height: parent.rowH
                    Text {
                        id: pwLbl
                        anchors.left: parent.left; anchors.top: pwBox.top
                        anchors.topMargin: 4 * root.s
                        width: 82 * root.s
                        text: "PASSKEY"
                        font.family: root.mono; font.bold: true
                        font.pixelSize: 11 * root.s
                        color: root.ink
                    }
                    Rectangle {
                        id: pwBox
                        anchors.left: pwLbl.right; anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: 40 * root.s
                        radius: 3 * root.s
                        color: "transparent"
                        border.color: root.errorMessage !== "" ? root.red : root.ink
                        border.width: 2 * root.s

                        TextInput {
                            id: pwd
                            anchors.left: parent.left; anchors.right: goBtn.left
                            anchors.top: parent.top; anchors.bottom: parent.bottom
                            anchors.leftMargin: 12 * root.s; anchors.rightMargin: 6 * root.s
                            verticalAlignment: TextInput.AlignVCenter
                            font.family: root.display
                            font.pixelSize: 20 * root.s
                            font.letterSpacing: 3 * root.s
                            color: root.ink
                            echoMode: TextInput.Password
                            passwordCharacter: "•"
                            clip: true
                            selectionColor: root.red
                            selectedTextColor: "#ffffff"
                            cursorDelegate: Rectangle { width: 3 * root.s; color: root.red }
                            onAccepted: root.login()
                        }
                        Text {
                            anchors.left: parent.left; anchors.leftMargin: 12 * root.s
                            anchors.verticalCenter: parent.verticalCenter
                            visible: pwd.text === ""
                            text: "ENTER PASSWORD"
                            font.family: root.mono; font.bold: true
                            font.pixelSize: 13 * root.s
                            font.letterSpacing: 1 * root.s
                            color: Qt.rgba(0.08, 0.08, 0.08, 0.4)
                        }
                        // Submit
                        Rectangle {
                            id: goBtn
                            anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom
                            anchors.margins: 3 * root.s
                            width: height + 8 * root.s
                            radius: 2 * root.s
                            color: goMa.pressed ? root.red : (goMa.containsMouse ? root.red : root.ink)
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Text {
                                anchors.centerIn: parent
                                text: "▶"
                                font.pixelSize: 14 * root.s
                                color: root.orange
                            }
                            MouseArea {
                                id: goMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.login()
                            }
                        }
                    }
                }
            }
        }

        // Copy block
        Text {
            anchors.right: parent.right; anchors.rightMargin: orangeCard.p
            y: orangeCard.rowY + orangeCard.rowH - implicitHeight
            width: Math.max(0, parent.width - loginBox.x - loginBox.width - 32 * root.s - orangeCard.p)
            visible: width > 120 * root.s
            wrapMode: Text.WordWrap
            text: "Identity verified at the edge. Every session is a negotiation between the machine and whoever remembers the password."
            font.family: root.mono; font.bold: true
            font.pixelSize: 10 * root.s
            lineHeight: 1.3
            color: root.ink
        }

        // Footer rule + meta + power circles
        Rectangle {
            id: rule
            anchors.left: parent.left; anchors.right: parent.right
            anchors.leftMargin: orangeCard.p; anchors.rightMargin: orangeCard.p
            anchors.bottom: parent.bottom; anchors.bottomMargin: 62 * root.s
            height: 2 * root.s; color: root.ink
        }
        Text {
            anchors.left: parent.left; anchors.leftMargin: orangeCard.p
            anchors.top: rule.bottom; anchors.topMargin: 10 * root.s
            text: "#" + Qt.formatDate(root.now, "ddMMM").toUpperCase() + root.pad(root.now.getHours())
            font.family: root.display
            font.pixelSize: 30 * root.s
            color: root.ink
        }
        Row {
            anchors.right: parent.right; anchors.rightMargin: orangeCard.p
            anchors.top: rule.bottom; anchors.topMargin: 10 * root.s
            spacing: 10 * root.s
            Repeater {
                model: [
                    { fill: 0.0,  act: 0 },   // sleep
                    { fill: 0.25, act: 1 },   // reboot
                    { fill: 0.5,  act: 2 }    // shutdown
                ]
                delegate: Item {
                    width: 34 * root.s; height: width
                    property bool hot: pma.containsMouse
                    onHotChanged: cv.requestPaint()
                    Canvas {
                        id: cv
                        anchors.fill: parent
                        onPaint: {
                            var c = getContext("2d");
                            c.reset();
                            var cx = width / 2, cy = height / 2, rad = width / 2 - 2 * root.s;
                            c.lineWidth = 2 * root.s;
                            c.strokeStyle = "#141414";
                            c.fillStyle = "#141414";
                            c.beginPath(); c.arc(cx, cy, rad, 0, Math.PI * 2); c.stroke();
                            var f = parent.hot ? 1.0 : modelData.fill;
                            if (f >= 1.0) {
                                c.beginPath(); c.arc(cx, cy, rad, 0, Math.PI * 2); c.fill();
                            } else if (f > 0) {
                                c.beginPath(); c.moveTo(cx, cy);
                                c.arc(cx, cy, rad, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * f);
                                c.closePath(); c.fill();
                            }
                        }
                    }
                    MouseArea {
                        id: pma
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (modelData.act === 0) sddm.suspend();
                            else if (modelData.act === 1) sddm.reboot();
                            else sddm.powerOff();
                        }
                    }
                }
            }
        }
    }

    // ── Green session card ───────────────────────────────────────────────────
    Rectangle {
        id: greenCard
        x: root.rightX; y: root.m + root.topH + root.gap
        width: root.halfW; height: root.botH
        radius: root.r
        color: root.green
        opacity: root.ui

        readonly property real p: 18 * root.s
        readonly property real rowA: 62 * root.s   // height of the bottom row
        readonly property real rowB: 66 * root.s   // height of the middle row

        // Outer frame
        Rectangle {
            anchors.fill: parent; anchors.margins: greenCard.p
            color: "transparent"
            radius: 16 * root.s
            border.color: root.ink; border.width: 2 * root.s

            // Upper pane: date readout
            Item {
                id: gUpper
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                anchors.bottom: gSession.top
                Text {
                    anchors.left: parent.left; anchors.leftMargin: 16 * root.s
                    anchors.top: parent.top; anchors.topMargin: 12 * root.s
                    text: Qt.formatDate(root.now, "dddd").toUpperCase() + "\n" + Qt.formatDate(root.now, "d MMMM yyyy").toUpperCase()
                    font.family: root.mono; font.bold: true
                    font.pixelSize: 12 * root.s
                    lineHeight: 1.3
                    color: root.ink
                }
            }

            // Session selector (click to cycle)
            Item {
                id: gSession
                anchors.left: parent.left; anchors.right: parent.right
                anchors.bottom: gBottom.top
                height: greenCard.rowB
                Rectangle { anchors.top: parent.top; width: parent.width; height: 2 * root.s; color: root.ink }
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 2 * root.s; color: root.ink }
                Rectangle {
                    anchors.fill: parent; anchors.topMargin: 2 * root.s; anchors.bottomMargin: 2 * root.s
                    color: sessMa.containsMouse ? root.ink : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }
                }
                Text {
                    anchors.left: parent.left; anchors.leftMargin: 16 * root.s
                    anchors.right: parent.right; anchors.rightMargin: 56 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.sessionLabel
                    font.family: root.display
                    fontSizeMode: Text.HorizontalFit
                    minimumPixelSize: 14 * root.s
                    font.pixelSize: 32 * root.s
                    elide: Text.ElideRight
                    color: sessMa.containsMouse ? root.green : root.ink
                }
                Text {
                    anchors.right: parent.right; anchors.rightMargin: 16 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    text: "DE"
                    font.family: root.display
                    font.pixelSize: 20 * root.s
                    color: sessMa.containsMouse ? root.green : root.ink
                }
                MouseArea {
                    id: sessMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof sessionModel !== "undefined" && sessionModel.count > 0)
                            root.sessionIndex = (root.sessionIndex + 1) % sessionModel.count;
                    }
                }
            }

            // Bottom: notice + stamp
            Item {
                id: gBottom
                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                height: greenCard.rowA
                Text {
                    anchors.left: parent.left; anchors.leftMargin: 16 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    text: "SELECT\nSESSION\nBEFORE LOGIN"
                    font.family: root.mono; font.bold: true
                    font.pixelSize: 10 * root.s
                    lineHeight: 1.25
                    color: root.ink
                }
                Text {
                    anchors.right: parent.right; anchors.rightMargin: 16 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    text: "©" + root.now.getFullYear()
                    font.family: root.mono; font.bold: true
                    font.pixelSize: 11 * root.s
                    color: root.ink
                }
            }
        }
    }

    // ── Grey clock card ──────────────────────────────────────────────────────
    Rectangle {
        id: greyCard
        x: root.rightX + root.halfW + root.gap; y: greenCard.y
        width: root.halfW; height: root.botH
        radius: root.r
        color: root.grey
        opacity: root.ui

        Text {
            anchors.left: parent.left; anchors.leftMargin: 24 * root.s
            anchors.top: parent.top; anchors.topMargin: 22 * root.s
            text: "Retro ai\ntecnology"
            font.family: "Chakra Petch"
            font.pixelSize: 24 * root.s
            lineHeight: 0.95
            color: root.ink
        }

        // Two-tone mark (top-right)
        Canvas {
            anchors.right: parent.right; anchors.rightMargin: 24 * root.s
            anchors.top: parent.top; anchors.topMargin: 22 * root.s
            width: 40 * root.s; height: width
            onPaint: {
                var c = getContext("2d");
                c.reset();
                c.scale(width / 100, height / 100);
                c.fillStyle = "#141414";
                c.beginPath(); c.moveTo(0, 40); c.lineTo(45, 0); c.lineTo(45, 45); c.lineTo(0, 85); c.closePath(); c.fill();
                c.beginPath(); c.moveTo(55, 0); c.lineTo(100, 0); c.lineTo(100, 45); c.lineTo(55, 85); c.closePath(); c.fill();
                c.beginPath(); c.moveTo(0, 100); c.lineTo(45, 100); c.lineTo(45, 62); c.closePath(); c.fill();
                c.beginPath(); c.moveTo(55, 100); c.lineTo(100, 100); c.lineTo(100, 62); c.lineTo(55, 100); c.closePath(); c.fill();
            }
        }

        // Big HH · MM
        Row {
            anchors.left: parent.left; anchors.leftMargin: 24 * root.s
            anchors.bottom: parent.bottom; anchors.bottomMargin: 20 * root.s
            spacing: 6 * root.s
            Text {
                text: root.pad(root.now.getHours())
                font.family: root.display
                font.pixelSize: Math.min(150 * root.s, (greyCard.width - 70 * root.s) / 2.7)
                color: root.ink
            }
            Text {
                text: root.pad(root.now.getMinutes())
                font.family: root.display
                font.pixelSize: Math.min(150 * root.s, (greyCard.width - 70 * root.s) / 2.7)
                color: root.red
            }
        }
        Text {
            anchors.right: parent.right; anchors.rightMargin: 20 * root.s
            anchors.bottom: parent.bottom; anchors.bottomMargin: 148 * root.s
            visible: greyCard.height > 200 * root.s
            text: "®"
            font.family: root.mono; font.bold: true
            font.pixelSize: 11 * root.s
            color: root.ink
        }
    }
}
