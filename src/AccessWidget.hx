import js.Browser;
import js.html.Element;

import pixi.core.math.Matrix;
import pixi.core.display.Bounds;
import pixi.core.display.Container;
import pixi.core.display.DisplayObject;
import pixi.interaction.EventEmitter;

using DisplayObjectHelper;

class AccessWidgetTree {
	public static var DebugAccessOrder : Bool = Util.getParameter("accessorder") == "1";

	@:isVar public var id(get, set) : Int;
	@:isVar public var accessWidget(get, set) : AccessWidget;
	@:isVar public var parent(get, set) : AccessWidgetTree;
	public var children : Map<Int, AccessWidgetTree> = new Map<Int, AccessWidgetTree>();
	public var childrenSize : Int = 0;
	@:isVar public var childrenChanged(get, set) : Bool;
	@:isVar public var changed(get, set) : Bool;
	public var zorder : Int = -9999;

	public function new(id : Int, ?accessWidget : AccessWidget, ?parent : AccessWidgetTree) {
		this.changed = false;
		this.childrenChanged = false;
		this.id = id;
		this.accessWidget = accessWidget;
		this.parent = parent;
	}

	public function get_id() : Int {
		return id;
	}

	public function set_id(id : Int) : Int {
		if (this.id != id) {
			var parent = parent;

			if (parent != null) {
				parent.removeChild(this, false);
			}

			this.id = id;
			changed = true;

			if (parent != null) {
				parent.addChild(this);
			}
		}

		return this.id;
	}

	public function get_accessWidget() : AccessWidget {
		return accessWidget;
	}

	public function set_accessWidget(accessWidget : AccessWidget) : AccessWidget {
		if (this.accessWidget != accessWidget) {
			this.accessWidget = accessWidget;

			if (this.accessWidget != null) {
				this.accessWidget.parent = this;
				this.changed = true;
			}
		}

		return this.accessWidget;
	}

	public function get_parent() : AccessWidgetTree {
		return parent;
	}

	public function set_parent(parent : AccessWidgetTree) : AccessWidgetTree {
		if (this.parent != parent) {
			this.parent = parent;

			if (this.parent != null) {
				this.parent.updateZorder();
			}
		}

		return this.parent;
	}

	public function get_changed() : Bool {
		return changed;
	}

	public function set_changed(changed : Bool) : Bool {
		if (this.changed != changed) {
			this.changed = changed;

			if (this.changed && parent != null) {
				parent.childrenChanged = true;
			}
		}

		return this.changed;
	}

	public function get_childrenChanged() : Bool {
		return childrenChanged;
	}

	public function set_childrenChanged(childrenChanged : Bool) : Bool {
		if (this.childrenChanged != childrenChanged) {
			this.childrenChanged = childrenChanged;

			if (this.childrenChanged && parent != null) {
				parent.childrenChanged = true;
			}
		}

		return this.childrenChanged;
	}

	public function updateZorder() : Bool {
		var previousZOrder = zorder;
		zorder = accessWidget != null ? accessWidget.zorder : -9999;

		for (child in children) {
			if (child.zorder > zorder) {
				zorder = child.zorder;
			}
		}

		if (zorder == -9999) {
			return false;
		}

		if (previousZOrder != zorder) {
			if (parent == null) {
				updateDisplay();
			} else if (!parent.updateZorder()) {
				updateDisplay();
			}

			return true;
		} else {
			return false;
		}
	}

	public function updateDisplay() : Void {
		updateVisible();

		for (child in children) {
			child.updateDisplay();
		}
	}

	public function updateVisible() : Void {
		if (accessWidget != null && accessWidget.element != null && accessWidget.clip.parent != null) {
			var nativeWidget : Dynamic = accessWidget.element;
			var clip : DisplayObject = accessWidget.clip;

			if (zorder >= AccessWidget.tree.zorder && clip.getClipVisible()) {
				nativeWidget.style.display = "block";
			} else {
				nativeWidget.style.display = "none";
			}

			if (DebugAccessOrder) {
				nativeWidget.setAttribute("zorder", '${zorder}');
				nativeWidget.setAttribute("nodeindex", '${accessWidget.nodeindex}');
			}

			if (untyped clip.onUpdateVisible != null) {
				untyped clip.onUpdateVisible();
			}
		}
	}

	public function updateAlpha(updateChildren : Bool = false) : Void {
		if (accessWidget != null && accessWidget.element != null && accessWidget.clip.parent != null && untyped accessWidget.clip.nativeWidget != null) {
			var nativeWidget : Dynamic = accessWidget.element;
			var clip : DisplayObject = accessWidget.clip;

			nativeWidget.style.opacity = clip.worldAlpha;

			if (untyped clip.onUpdateAlpha != null) {
				untyped clip.onUpdateAlpha();
			}
		}
	}

	public function updateTransform() {
		if (accessWidget != null && accessWidget.element != null && accessWidget.clip.parent != null && untyped accessWidget.clip.nativeWidget != null) {
			var nativeWidget : Dynamic = accessWidget.element;
			var clip : DisplayObject = accessWidget.clip;

			var transform = getTransform();

			if (Platform.isIE) {
				nativeWidget.style.transform = 'matrix(${transform.a}, ${transform.b}, ${transform.c}, ${transform.d}, 0, 0)';

				nativeWidget.style.left = '${transform.tx}px';
				nativeWidget.style.top = '${transform.tx}px';
			} else {
				nativeWidget.style.transform = 'matrix(${transform.a}, ${transform.b}, ${transform.c}, ${transform.d}, ${transform.tx}, ${transform.ty})';
			}

			if (DebugAccessOrder) {
				nativeWidget.setAttribute("worldTransform", 'matrix(${clip.worldTransform.a}, ${clip.worldTransform.b}, ${clip.worldTransform.c}, ${clip.worldTransform.d}, ${clip.worldTransform.tx}, ${clip.worldTransform.ty})');
			}

			if (untyped clip.onUpdateTransform != null) {
				untyped clip.onUpdateTransform();
			}
		}
	}

	private function getTransform(append : Bool = true) : Matrix {
		if (accessWidget != null && accessWidget.clip != null && accessWidget.clip.parent != null && untyped accessWidget.clip.nativeWidget != null) {
			if (append && parent != null) {
				var parentTransform = parent.getTransform(false);
				return accessWidget.clip.worldTransform.clone().append(parentTransform.clone().invert());
			} else {
				return accessWidget.clip.worldTransform;
			}
		} else if (!append && parent != null) {
			return parent.getTransform();
		} else {
			return new Matrix();
		}
	}

	private function getWidth() : Float {
		if (accessWidget != null) {
			var clip : DisplayObject = accessWidget.clip;

			if (untyped clip.getWidth == null) {
				var bounds = clip.getBounds(true);
				return bounds.width * clip.worldTransform.a + bounds.height * clip.worldTransform.c;
			} else {
				return untyped clip.getWidth();
			}
		} else {
			return 0;
		}
	}

	private function getHeight() : Float {
		if (accessWidget != null) {
			var clip : DisplayObject = accessWidget.clip;

			if (untyped clip.getHeight == null) {
				var bounds = clip.getBounds(true);
				return bounds.width * clip.worldTransform.b + bounds.height * clip.worldTransform.d;
			} else {
				return untyped clip.getHeight();
			}
		} else {
			return 0;
		}
	}

	public function getChild(id : Int) : AccessWidgetTree {
		return children.get(id);
	}

	public function addChild(child : AccessWidgetTree) : Void {
		if (child.parent != null) {
			child.parent.removeChild(child, false);
		}

		var previousChild = getChild(child.id);

		if (previousChild != null) {
			if (previousChild.accessWidget != null && previousChild.accessWidget != child.accessWidget) {
				if (previousChild.accessWidget.nodeindex == null) {
					previousChild.id = childrenSize;

					childrenSize++;
					children.set(child.id, child);
					child.parent = this;
				} else {
					AccessWidget.addAccessWidgetWithoutNodeindex(child.accessWidget, child.accessWidget.clip.parent);
					previousChild.accessWidget.once("removed", function() {
						if (child != null && child.accessWidget != null) {
							AccessWidget.addAccessWidget(child.accessWidget);
						}
					});
				}
			} else {
				previousChild.accessWidget = child.accessWidget;
			}
		} else {
			childrenSize++;
			children.set(child.id, child);
			child.parent = this;
		}

		childrenChanged = true;
	}

	public function removeChild(child : AccessWidgetTree, ?destroy : Bool = true) : Void {
		if (destroy && child.accessWidget != null) {
			child.accessWidget.element = null;
			untyped child.accessWidget.clip.accessWidget = null;
		}

		if (children.get(child.id) == child) {
			children.remove(child.id);
			childrenSize--;
		}

		child.parent = null;

		if (destroy && childrenSize == 0 && accessWidget == null && parent != null) {
			parent.removeChild(this);
		} else {
			updateZorder();
		}

		childrenChanged = true;
	}
}

class AccessWidget extends EventEmitter {
	// ARIA-role to HTML tag map
	private static var accessRoleMap : Map<String, String> = [
		"button" => "button",
		"checkbox" => "button",
		"radio" => "button",
		"menu" => "button",
		"listitem" => "button",
		"menuitem" => "button",
		"tab" => "button",
		"banner" => "header",
		"main" => "section",
		"navigation" => "nav",
		"contentinfo" => "footer",
		"form" => "form",
		"textbox" => "input",
	];

	public static var zIndexValues = {
		"canvas" : "0",
		"accessButton" : "2",
		"droparea" : "1",
		"nativeWidget" : "2"
	};

	public static var tree : AccessWidgetTree = new AccessWidgetTree(0);

	public var clip : DisplayObject;
	@:isVar public var element(get, set) : Element;

	@:isVar public var nodeindex(get, set) : Array<Int>;
	@:isVar public var zorder(get, set) : Int;

	public var tabindex(get, set) : Int;
	public var role(get, set) : String;
	public var description(get, set) : String;
	public var id(get, set) : String;
	public var enabled(get, set) : Bool;
	public var autocomplete(get, set) : String;

	@:isVar public var parent(get, set) : AccessWidgetTree;

	public function new(clip : DisplayObject, element : Element, ?nodeindex : Array<Int>, ?zorder : Int = 0) {
		super();

		this.clip = clip;
		this.element = element;
		this.nodeindex = nodeindex;
		this.zorder = zorder;

		clip.onAdded(function() {
			addAccessWidget(this);

			return function() {
				removeAccessWidget(this);
			}
		});
	}

	public static inline function createAccessWidget(clip : DisplayObject, attributes : Array<Array<String>>) : Void {
		if (untyped clip.accessWidget != null) {
			removeAccessWidget(untyped clip.accessWidget);
		}

		var attributesMap = new Map<String, String>();

		for (kv in attributes) {
			attributesMap.set(kv[0], kv[1]);
		}

		var tagName = attributesMap.get("tag");

		if (tagName == null) {
			tagName = accessRoleMap.get(attributesMap.get("role"));
		}

		if (tagName == null) {
			tagName = "div";
		}

		untyped clip.accessWidget = new AccessWidget(clip, Browser.document.createElement(tagName));
		untyped clip.accessWidget.addAccessAttributes(attributesMap);
	}

	public function get_element() : Element {
		return element;
	}

	public function set_element(element : Element) : Element {
		if (this.element != element) {
			if (this.element != null && this.element.parentNode != null) {
				this.element.parentNode.removeChild(this.element);

				untyped __js__("delete element;");
			}

			this.element = element;

			if (this.element != null) {
				var tagName = this.element.tagName.toLowerCase();

				// Add focus notification. Used for focus control
				this.element.addEventListener("focus", function () {
					clip.emit("focus");

					var parent : DisplayObject = clip.parent;

					if (parent != null) {
						parent.emitEvent("childfocused", clip);
					}
				});

				// Add blur notification. Used for focus control
				this.element.addEventListener("blur", function () {
					clip.emit("blur");
				});

				if (this.element.style.zIndex == null) {
					this.element.style.zIndex = AccessWidget.zIndexValues.accessButton;
				}

				if (tagName == "button") {
					this.element.classList.add("accessButton");
				} else if (tagName == "div") {
					this.element.classList.add("accessElement");
				}

				if (parent != null) {
					parent.changed = true;
				}
			}
		}

		return this.element;
	}

	public function get_nodeindex() : Array<Int> {
		return nodeindex;
	}

	public function set_nodeindex(nodeindex : Array<Int>) : Array<Int> {
		if (this.nodeindex != nodeindex) {
			this.nodeindex = nodeindex;

			if (clip.parent != null) {
				addAccessWidget(this);
			}
		}

		return this.nodeindex;
	}

	public function get_zorder() : Int {
		return zorder;
	}

	public function set_zorder(zorder : Int) : Int {
		if (this.zorder != zorder) {
			this.zorder = zorder;

			if (this.parent != null) {
				this.parent.updateZorder();
			}
		}

		return this.zorder;
	}

	public function get_tabindex() : Int {
		return element.tabIndex;
	}

	public function set_tabindex(tabindex : Int) : Int {
		element.tabIndex = tabindex;

		return this.tabindex;
	}

	public function get_role() : String {
		return element.getAttribute("role");
	}

	public function set_role(role : String) : String {
		element.setAttribute("role", role);

		// Sets events
		if (accessRoleMap.get(role) == "button") {
			element.onclick = function(e) {
				if (e.target == element) {
					if (untyped clip.accessCallback != null) {
						untyped clip.accessCallback();
					} else {
						RenderSupportJSPixi.emulateMouseClickOnClip(clip);
					}
				}
			};

			var onFocus = element.onfocus;
			var onBlur = element.onblur;

			element.onfocus = function(e) {
				if (onFocus != null) {
					onFocus(e);
				}

				element.classList.add('focused');
			};

			element.onblur = function(e) {
				if (onBlur != null) {
					onBlur(e);
				}

				element.classList.remove('focused');
			};

			if (element.tabIndex == null) {
				element.tabIndex = 0;
			}
		} else if (role == "textbox") {
			element.onkeyup = function(e) {
				if (e.keyCode == 13 && untyped clip.accessCallback != null) {
					untyped clip.accessCallback();
				}
			}

			if (element.tabIndex == null) {
				element.tabIndex = 0;
			}
		} else if (role == "iframe") {
			if (element.tabIndex == null) {
				element.tabIndex = 0;
			}
		}

		return this.role;
	}

	public function get_description() : String {
		return element.getAttribute("aria-label");
	}

	public function set_description(description : String) : String {
		if (description != "") {
			element.setAttribute("aria-label", description);
		}

		return this.description;
	}

	public function get_id() : String {
		return element.id;
	}

	public function set_id(id : String) : String {
		element.id = id;

		return this.id;
	}

	public function get_enabled() : Bool {
		return element.getAttribute("disabled") != null;
	}

	public function set_enabled(enabled : Bool) : Bool {
		if (enabled) {
			element.removeAttribute("disabled");
		} else {
			element.setAttribute("disabled", "disabled");
		}

		return this.enabled;
	}

	public function get_autocomplete() : String {
		return untyped element.autocomplete;
	}

	public function set_autocomplete(autocomplete : String) : String {
		untyped element.autocomplete = autocomplete;

		if (untyped clip.setReadOnly != null) {
			untyped clip.setReadOnly(untyped clip.readOnly);
		}

		return this.autocomplete;
	}

	public function get_parent() : AccessWidgetTree {
		return parent;
	}

	public function set_parent(parent : AccessWidgetTree) : AccessWidgetTree {
		if (this.parent != parent) {
			this.parent = parent;

			if (parent != null) {
				emit("added");
				parent.updateZorder();
			}
		}

		return this.parent;
	}

	private static inline function parseNodeIndex(nodeindex : String) : Array<Int> {
		var nodeindexStrings = ~/ /g.split(nodeindex);
		var parsedNodeindex = new Array();

		for (i in 0...nodeindexStrings.length) {
			parsedNodeindex = parsedNodeindex.concat([Std.parseInt(nodeindexStrings[i])]);
		}

		return parsedNodeindex;
	}

	public function addAccessAttributes(attributes : Map<String, String>) : Void {
		for (key in attributes.keys()) {
			switch (key) {
				case "role" : role = attributes.get(key);
				case "description" : description = attributes.get(key);
				case "zorder" : zorder = Std.parseInt(attributes.get(key));
				case "id" : id = attributes.get(key);
				case "enabled" : enabled = attributes.get(key) == "true";
				case "nodeindex" : nodeindex = parseNodeIndex(attributes.get(key));
				case "tabindex" : tabindex = Std.parseInt(attributes.get(key));
				case "autocomplete" : autocomplete = attributes.get(key);
				default : {
					if (element != null) {
						if (key.indexOf("style:") == 0) {
							element.style.setProperty(key.substr(6, key.length), attributes.get(key));
						} else {
							element.setAttribute(key, attributes.get(key));
						}
					}
				}
			}
		}
	}

	public function updateAlpha() : Void {
		if (parent != null) {
			parent.updateAlpha();
		}
	}

	public function updateTransform() : Void {
		if (parent != null) {
			parent.updateTransform();
		}
	}

	public function updateVisible() : Void {
		if (parent != null) {
			parent.updateVisible();
		}
	}

	public static function addAccessWidget(accessWidget : AccessWidget, ?nodeindexPosition : Int = 0, ?tree : AccessWidgetTree) : Void {
		if (accessWidget.nodeindex == null || accessWidget.nodeindex.length == 0) {
			addAccessWidgetWithoutNodeindex(accessWidget, accessWidget.clip.parent);

			return;
		}

		if (tree == null) {
			tree = AccessWidget.tree;
		}

		var id = accessWidget.nodeindex[nodeindexPosition];

		if (nodeindexPosition == accessWidget.nodeindex.length - 1) {
			if (accessWidget.parent != null) {
				accessWidget.parent.id = id;
				tree.addChild(accessWidget.parent);
			} else {
				tree.addChild(new AccessWidgetTree(id, accessWidget));
			}
		} else {
			if (tree.getChild(id) == null) {
				tree.addChild(new AccessWidgetTree(id, null));
			}

			addAccessWidget(accessWidget, nodeindexPosition + 1, tree.getChild(id));
		}
	}

	public static function addAccessWidgetWithoutNodeindex(accessWidget : AccessWidget, parent : DisplayObject) : Void {
		if (parent == null) {
			return;
		} else if (parent == RenderSupportJSPixi.PixiStage || (untyped parent.accessWidget != null && untyped parent.accessWidget.parent != null)) {
			var id = parent == RenderSupportJSPixi.PixiStage ? AccessWidget.tree.childrenSize : untyped parent.accessWidget.parent.childrenSize;
			var tree = parent == RenderSupportJSPixi.PixiStage ? AccessWidget.tree : untyped parent.accessWidget.parent;

			if (accessWidget.parent != null) {
				accessWidget.parent.id = id;
				tree.addChild(accessWidget.parent);
			} else {
				tree.addChild(new AccessWidgetTree(tree.childrenSize, accessWidget));
			}
		} else if (parent.parent == null) {
			parent.once("added", function() {
				if (parent != null && parent.parent != null && accessWidget != null) {
					addAccessWidgetWithoutNodeindex(accessWidget, parent);
				}
			});
		} else if (untyped parent.accessWidget != null && untyped parent.accessWidget.parent == null) {
			untyped parent.accessWidget.once("added", function() {
				if (parent != null && parent.parent != null && parent.accessWidget != null) {
					addAccessWidgetWithoutNodeindex(accessWidget, parent);
				}
			});
		} else {
			addAccessWidgetWithoutNodeindex(accessWidget, parent.parent);
		}
	}

	public static function removeAccessWidget(accessWidget : AccessWidget) : Void {
		if (accessWidget != null && accessWidget.parent != null) {
			removeAccessWidgetTree(accessWidget.parent);
			accessWidget.emit("removed");
		}
	}

	private static function removeAccessWidgetTree(tree : AccessWidgetTree) : Void {
		if (tree.parent != null) {
			tree.parent.removeChild(tree);
		}
	}

	public static function printTree(?tree : AccessWidgetTree, ?id : String = "") : Void {
		if (tree == null) {
			tree = AccessWidget.tree;
		}

		for (key in tree.children.keys()) {
			var accessWidget = tree.children.get(key).accessWidget;
			trace(id + key + " " + (accessWidget != null && accessWidget.element != null ? accessWidget.nodeindex + " " + accessWidget.element.getAttribute("role") : "null"));
			printTree(tree.children.get(key), id + key + " ");
		}
	}

	public static function updateAccessTree(?tree : AccessWidgetTree, ?parent : Element, ?previousElement : Element, ?childrenChanged : Bool = false) : Bool {
		if (tree == null) {
			tree = AccessWidget.tree;

			if (AccessWidgetTree.DebugAccessOrder && tree.childrenChanged) {
				printTree();
			}
		}

		if (!tree.childrenChanged) {
			return false;
		}

		if (parent == null) {
			parent = Browser.document.body;
		}

		for (key in tree.children.keys()) {
			var child = tree.children.get(key);

			if (!child.childrenChanged && !child.changed) {
				continue;
			}

			var accessWidget = child.accessWidget;

			if (accessWidget != null && accessWidget.element != null) {
				if (child.changed) {
					if (previousElement != null && previousElement.nextSibling != null) {
						parent.insertBefore(accessWidget.element, previousElement.nextSibling);
					} else {
						parent.appendChild(accessWidget.element);
					}

					child.changed = false;
				}

				previousElement = accessWidget.element;
				updateAccessTree(child, accessWidget.element, accessWidget.element.firstElementChild, true);
			} else {
				updateAccessTree(child, parent, previousElement, true);
			}
		}

		tree.childrenChanged = false;

		return true;
	}
}