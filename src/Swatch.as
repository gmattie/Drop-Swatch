package
{
//Imports
import com.caurina.transitions.Equations;
import com.caurina.transitions.Tweener;
import com.mattie.utils.colorUtils.parseColor;
import flash.display.BlendMode;
import flash.display.DisplayObject;
import flash.display.Shape;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.events.TransformGestureEvent;
import flash.filters.DropShadowFilter;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Rectangle;
import flash.text.AntiAliasType;
import flash.text.Font;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFieldType;
import flash.text.TextFormat;
import flash.ui.Multitouch;
import flash.ui.MultitouchInputMode;
import flash.utils.Timer;
		
//Class
public class Swatch extends Sprite
	{
	//Constants
	public static const PREFS_RANDOM_SWATCH_COLOR:String = "prefsRandomSwatchColor";
	public static const PREFS_RANDOM_SWATCH_TEXTURE:String = "prefsRandomSwatchTexture";
	public static const PREFS_SHOW_SWATCH_VALUES:String = "prefsShowSwatchValues";
	
	private static const ANIMATION_DURATION:Number = 0.5;
	private static const VELOCITY_TIMER_DELAY:Number = 30.0;
	private static const MOMENTUM_TIMER_DELAY:Number = 20.0;
	private static const MINIMUM_VELOCITY:Number = 0.1;
	private static const FRICTION:Number = 0.9;
	private static const ZOOM_SCALE:Number = 1.25;
	private static const ZOOM_SHADOW:Number = 40.0;
	private static const UNZOOM_SHADOW:Number = 5.0;
	
	//Properties
	private var swatchColorProperty:uint;
	private var swatchSizeProperty:Number;
	private var swatchRotationProperty:Number;
	private var swatchTextureProperty:String;
	private var swatchTextureRotationProperty:Number;
	private var stageBoundsProperty:Rectangle;
	private var isActiveProperty:Boolean;
	private var isSelected:Boolean;
	private var isAnimating:Boolean;
	
	//Variables
	public static var previousSwatchColor:Number = NaN;
	public static var hasRandomColor:Boolean = true;
	public static var hasRandomTexture:Boolean = true;
	public static var showValues:Boolean = true;
	
	public var dropShadowAmount:Number;
	
	private var savedProperties:Object;
	private var canvas:Sprite;
	private var canvasTexture:SwatchTexture;
	private var argbTextField:TextField;
	private var hexTextField:TextField;
	private var velocityTimer:Timer;
	private var momentumTimer:Timer;
	private var velocityX:Number;
	private var velocityY:Number;
	private var originX:Number;
	private var originY:Number;	
	private var maskedBounds:Rectangle;
	
	//Constructor
	public function Swatch(savedProperties:Object = null)
		{
		this.savedProperties = savedProperties;

		addEventListener(Event.ADDED_TO_STAGE, init);
		}

	//Initialize
	private function init(evt:Event):void
		{
		removeEventListener(Event.ADDED_TO_STAGE, init);
		
		swatchSize = (savedProperties != null) ? savedProperties.size : Math.random() * (Math.min(DropSwatch.DEFAULT_STAGE_HEIGHT, stage.stageHeight) * 0.10) + (Math.min(DropSwatch.DEFAULT_STAGE_HEIGHT, stage.stageHeight) * 0.30);
		swatchRotation = (savedProperties != null) ? savedProperties.rotation : Math.random() * 50 - 25;

		stageBoundsProperty = new Rectangle(0, 0, stage.stageWidth, stage.stageHeight);
		
		canvas = new Sprite();
		canvas.graphics.beginFill(0x000000, 1.0);
		canvas.graphics.drawRect(-swatchSize / 2, -swatchSize / 2, swatchSize, swatchSize);
		canvas.graphics.endFill();
		
		canvasTexture = new SwatchTexture(swatchSize);

		argbTextField = swatchTextField();
		argbTextField.x = canvas.x - canvas.width / 2 + 5;
		argbTextField.y = canvas.y - canvas.height / 2 + 5;
		
		hexTextField = swatchTextField();
		hexTextField.x = canvas.x - canvas.width / 2 + 5;
		hexTextField.y = canvas.y + canvas.height / 2 - hexTextField.height - swatchSize / 10;
		
		addChild(canvas);
		addChild(canvasTexture);
		addChild(argbTextField);
		addChild(hexTextField);
		
		if	(savedProperties != null)
			swatchColorProperty = savedProperties.color;
			else
			if	(isNaN(Swatch.previousSwatchColor))
				if	(Swatch.hasRandomColor)
					swatchColorProperty = uint(0xFF << 24 | (Math.random() * 0xFFFFFF));
					else
					swatchColorProperty = 0xFFFFFFFF;
				else
				if	(Swatch.hasRandomColor)
					swatchColorProperty = uint(((Swatch.previousSwatchColor >> 24) & 0xFF) << 24 | (Math.random() * 0xFFFFFF));
					else
					swatchColorProperty = Swatch.previousSwatchColor;
					
		updateColor(swatchColorProperty);
		
		if	(savedProperties != null)
			swatchTextureProperty = savedProperties.texture;
			else
			if	(SwatchTexture.previousSwatchTexture == null)
				if	(Swatch.hasRandomTexture)
					swatchTextureProperty = SwatchTexture.randomTexture;
					else
					swatchTextureProperty = SwatchTexture.NONE;
				else
				if	(Swatch.hasRandomTexture)
					swatchTextureProperty = SwatchTexture.randomTexture;
					else
					swatchTextureProperty = SwatchTexture.previousSwatchTexture;

		updateTexture(swatchTextureProperty);
		
		
		if	(savedProperties != null)
			swatchTextureRotationProperty = savedProperties.textureRotation;
			else
			if	(isNaN(SwatchTexture.previousSwatchTextureRotation))
				if	(Swatch.hasRandomTexture)
					swatchTextureRotationProperty = SwatchTexture.randomTextureRotation;
					else
					swatchTextureRotationProperty = 0.0;
				else
				if	(Swatch.hasRandomTexture)
					swatchTextureRotationProperty = SwatchTexture.randomTextureRotation;
					else
					swatchTextureRotationProperty = SwatchTexture.previousSwatchTextureRotation;
		
		updateTextureRotation(swatchTextureRotationProperty);

		if	(!Swatch.showValues)
			argbTextField.alpha = hexTextField.alpha = 0;

		if	(savedProperties != null)
			{
			alpha = ((swatchColor >> 24) & 0xFF) / 255;
			dropShadowAmount = UNZOOM_SHADOW;
			rotation = swatchRotation;
			filters = [new DropShadowFilter(dropShadowAmount, 90, 0x000000, 1.0, dropShadowAmount * 2, dropShadowAmount * 2, 1.0, 3)];
			}
			else
			{
			alpha = 0;
			dropShadowAmount = 100.0;
			scaleX = scaleY = 1.5;
			isActive = true;
			isAnimating = true;
			
			Tweener.addTween(this, 	{
									time: ANIMATION_DURATION,
									transition:Equations.easeInOutCubic,
									dropShadowAmount: UNZOOM_SHADOW,
									alpha: ((swatchColor >> 24) & 0xFF) / 255,
									scaleX: 1.0,
									scaleY: 1.0,
									rotation: swatchRotation,
									onUpdate: updateDropShadow,
									onComplete: completeDropShadow,
									onCompleteParams: [UNZOOM_SHADOW]
									}
							);
			}

		velocityTimer = new Timer(VELOCITY_TIMER_DELAY, 0);
		velocityTimer.addEventListener(TimerEvent.TIMER, velocityTimerEventHandler);
		
		momentumTimer = new Timer(MOMENTUM_TIMER_DELAY, 0);
		momentumTimer.addEventListener(TimerEvent.TIMER, momentumTimerEventHandler);
		
		Multitouch.inputMode = MultitouchInputMode.GESTURE;
		
		stage.addEventListener(DropSwatchEvent.SELECT, selectSwatchEventHandler);
		stage.addEventListener(DropSwatchEvent.COLOR, updateSwatchColorEventHandler);
		stage.addEventListener(DropSwatchEvent.TEXTURE, updateSwatchTextureEventHandler);
		stage.addEventListener(DropSwatchEvent.VALUES, updateSwatchValuesEventHandler);
		stage.addEventListener(DropSwatchEvent.REMOVE_ALL, removeAllSwatchesEventHandler);
		
		addEventListener(MouseEvent.MOUSE_DOWN, mouseDownEventHandler);
		addEventListener(TransformGestureEvent.GESTURE_ZOOM , resizeGestureEventHandler);
		addEventListener(TransformGestureEvent.GESTURE_ROTATE, rotateGestureEventHandler);
		}
		
	//Create Text Field
	private function swatchTextField():TextField
		{
		var swatchFont:Font = DropSwatch.swatchFont;
		
		var textFormat:TextFormat = new TextFormat();
		textFormat.bold = true;
		textFormat.color = 0x000000;
		textFormat.font = swatchFont.fontName;
		textFormat.size = swatchSize / 10;
		
		var result:TextField = new TextField();
		result.antiAliasType = AntiAliasType.ADVANCED;
		result.autoSize = TextFieldAutoSize.LEFT;
		result.blendMode = BlendMode.ERASE;
		result.defaultTextFormat = textFormat;
		result.embedFonts = true;
		result.multiline = true;
		result.selectable = false;
		result.type = TextFieldType.DYNAMIC;
		
		return result;
		}
	
	//Mouse Down Event Handler
	private function mouseDownEventHandler(evt:MouseEvent):void
		{
		if	(DropSwatch.controller.preferencesPanel && DropSwatch.controller.preferencesPanel.visible)
			{
			DropSwatch.controller.preferencesPanel.hide();
			return;
			}
			
		evt.stopImmediatePropagation();
		
		if	(!isAnimating)
			{
			parent.addChild(this);
			
			originX = x;
			originY = y;
			
			if	(momentumTimer.running)
				momentumTimer.stop();
			
			addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveEventHandler);
			addEventListener(MouseEvent.CLICK, mouseClickEventHandler);
			}
		}

	//Mouse Move Event Handler
	private function mouseMoveEventHandler(evt:MouseEvent):void
		{
		evt.stopImmediatePropagation();
		
		removeEventListener(MouseEvent.CLICK, mouseClickEventHandler);
		removeEventListener(MouseEvent.MOUSE_MOVE, mouseMoveEventHandler);
		
		mouseMoveEventBypass();
		}
		
	//Mouse Move Event Bypass
	private function mouseMoveEventBypass():void
		{
		startDrag();
			
		addEventListener(MouseEvent.MOUSE_UP, mouseUpEventHandler);
		addEventListener(MouseEvent.MOUSE_OUT, mouseUpEventHandler);
		
		velocityTimer.start();
		}
		
	//Mouse Click Event Handler
	private function mouseClickEventHandler(evt:MouseEvent):void
		{
		evt.stopImmediatePropagation();
		
		if	(isSelected)
			deselect();
			else
			{
			isSelected = true;
			isAnimating = true;
			
			Tweener.addTween(this,	{
							 		time: ANIMATION_DURATION, 
									transition: Equations.easeInOutCubic,
									dropShadowAmount: ZOOM_SHADOW,
									scaleX: scaleX * ZOOM_SCALE,
									scaleY: scaleY * ZOOM_SCALE,
									rotation: swatchRotation + (Math.random() * 20 - 10),
									onUpdate: updateDropShadow,
									onComplete: completeDropShadow,
									onCompleteParams: [ZOOM_SHADOW]
									}
							);
			
			stage.dispatchEvent(new DropSwatchEvent(DropSwatchEvent.SELECT, this, swatchColorProperty));
			}
		
		removeEventListener(MouseEvent.MOUSE_MOVE, mouseMoveEventHandler);
		removeEventListener(MouseEvent.CLICK, mouseClickEventHandler);
		}
		
	//Mouse Up Event Handler
	private function mouseUpEventHandler(evt:MouseEvent):void
		{
		evt.stopImmediatePropagation();
		
		stopDrag();
				
		removeEventListener(MouseEvent.MOUSE_UP, mouseUpEventHandler);
		removeEventListener(MouseEvent.MOUSE_OUT, mouseUpEventHandler);
		
		velocityTimer.stop();		
		
		if	(Math.abs(velocityX) > 1 || Math.abs(velocityY) > 1)
			{
			momentumTimer.start();
			
			if	(isSelected)
				deselect();
			}
		}
	
	//Resize Gesture Event Handler
	private function resizeGestureEventHandler(evt:TransformGestureEvent):void
		{
		evt.stopImmediatePropagation();

		if	(!isAnimating)
			{
			parent.addChild(this);
			
			swatchSize *= evt.scaleX;
			
			if	(swatchSize > stage.stageHeight * 0.20 && swatchSize < Math.min(DropSwatch.DEFAULT_STAGE_HEIGHT, stage.stageHeight) / ZOOM_SCALE)
				scaleX = scaleY *= evt.scaleX;
				else
				swatchSize /= evt.scaleX;
			}
		}
	
	//Rotate Gesture Event Handler
	private function rotateGestureEventHandler(evt:TransformGestureEvent):void
		{
		evt.stopImmediatePropagation();
		
		if	(!isAnimating)
			{
			parent.addChild(this);
			swatchRotation = rotation += evt.rotation;
			}
		}
		
	//Momentum Timer Event Handler
	private function momentumTimerEventHandler(evt:TimerEvent):void
		{
		if	(stageBounds.intersects(getBounds(parent)))
			{
			if	(Math.abs(velocityX) > MINIMUM_VELOCITY)
				x += velocityX *= FRICTION;
				
			if	(Math.abs(velocityY) > MINIMUM_VELOCITY)
				y += velocityY *= FRICTION;
			
			if	((Math.abs(velocityX) <= MINIMUM_VELOCITY && Math.abs(velocityY) <= MINIMUM_VELOCITY))
				momentumTimer.stop();
			}
			else
			dispose();
		}
	
	//Velocity Timer Event Handler
	private function velocityTimerEventHandler(evt:TimerEvent):void
		{
		velocityX = x - originX;
		velocityY = y - originY;
		originX = x;
		originY = y;
		}
		
	//Update Color
	private function updateColor(argb:Number):void
		{
		var parsedColor:Object = parseColor(argb);
		argbTextField.text = "A: " + parsedColor.alpha + "\nR: " + parsedColor.red + "\nG: " + parsedColor.green + "\nB: " + parsedColor.blue;
		hexTextField.text = "H: " + parsedColor.hex;
		
		var colorTransform:ColorTransform = new ColorTransform();
		colorTransform.redOffset = parsedColor.red;
		colorTransform.greenOffset = parsedColor.green;
		colorTransform.blueOffset = parsedColor.blue;		
		
		canvas.transform.colorTransform = colorTransform;
		alpha = parsedColor.alpha / 255;
		
		swatchColor = parsedColor.color;
		}
		
	//Update Texture
	private function updateTexture(texture:String):void
		{
		swatchTextureProperty = canvasTexture.texture = texture;
		}
		
	//Update Texture Rotation
	private function updateTextureRotation(textureRotation:Number):void
		{
		swatchTextureRotationProperty = canvasTexture.textureRotation = textureRotation;
		}
		
	//Update Drop Shadow
	private function updateDropShadow():void
		{
		filters = [new DropShadowFilter(dropShadowAmount, 90, 0x000000, 1.0, dropShadowAmount * 2, dropShadowAmount * 2, 1.0, 2)];
		}
		
	//Complete Drop Shadow
	private function completeDropShadow(dropShadowAmount:Number):void
		{
		isAnimating = false;
		this.dropShadowAmount = dropShadowAmount;
		
		if	(dropShadowAmount == UNZOOM_SHADOW)
			filters = [new DropShadowFilter(dropShadowAmount, 90, 0x000000, 1.0, dropShadowAmount * 2, dropShadowAmount * 2, 1.0, 3)];
		}
		
	//Deselect Swatch
	public function deselect(animate:Boolean = true):void
		{
		isSelected = false;
		
		if	(animate)
			{
			isAnimating = true;
			
			Tweener.addTween(this,	{
									time: ANIMATION_DURATION,
									transition: Equations.easeInOutCubic,
									dropShadowAmount: UNZOOM_SHADOW,
									scaleX: scaleX / ZOOM_SCALE,
									scaleY: scaleY / ZOOM_SCALE,
									rotation: swatchRotation,
									onUpdate: updateDropShadow,
									onComplete: completeDropShadow,
									onCompleteParams: [UNZOOM_SHADOW]
									}
							);
			}
			else
			{
			scaleX = scaleX / ZOOM_SCALE;
			scaleY = scaleY / ZOOM_SCALE;
			rotation = swatchRotation;
			completeDropShadow(UNZOOM_SHADOW);
			}
		
		Swatch.previousSwatchColor = swatchColorProperty;
		SwatchTexture.previousSwatchTexture = swatchTextureProperty;
		SwatchTexture.previousSwatchTextureRotation = swatchTextureRotationProperty;
		
		stage.dispatchEvent(new DropSwatchEvent(DropSwatchEvent.SELECT, null));
		}
		
	//Select Swatch Event Handler
	private function selectSwatchEventHandler(evt:DropSwatchEvent):void
		{
		if	(evt.swatchTarget)
			if	(this == evt.swatchTarget)
				isActive = true;
				else
				isActive = false;
			else
			isActive = true;
		}
		
	//Update Swatch Color Event Handler
	private function updateSwatchColorEventHandler(evt:DropSwatchEvent):void
		{
		if	(this == evt.swatchTarget)
			updateColor(evt.swatchColor);
		}
		
	//Update Swatch Texture Event Handler
	private function updateSwatchTextureEventHandler(evt:DropSwatchEvent):void
		{
		if	(this == evt.swatchTarget && evt.swatchTexture)
			if	(swatchTextureProperty == evt.swatchTexture)
				updateTextureRotation((canvasTexture.textureRotation == 270.0) ? 0.0 : canvasTexture.textureRotation += 90.0);
				else
				updateTexture(evt.swatchTexture);
		}
		
	//Update Swatch Values Event Handler
	private function updateSwatchValuesEventHandler(evt:DropSwatchEvent):void
		{
		Swatch.showValues = evt.swatchValues;
		
		Tweener.addTween(argbTextField, {time: ANIMATION_DURATION, transition: Equations.easeInOutCubic, alpha: evt.swatchValues});
		Tweener.addTween(hexTextField, {time: ANIMATION_DURATION, transition: Equations.easeInOutCubic, alpha: evt.swatchValues});
		}
	
	//Remove All Swatches Event Handler
	private function removeAllSwatchesEventHandler(evt:DropSwatchEvent):void
		{
		removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownEventHandler);
		removeEventListener(TransformGestureEvent.GESTURE_ZOOM , resizeGestureEventHandler);
		removeEventListener(TransformGestureEvent.GESTURE_ROTATE, rotateGestureEventHandler);

		Tweener.addTween(this, isSelected	? 	{
						 						time: Math.random() * ANIMATION_DURATION / 2 + ANIMATION_DURATION,
												transition: Equations.easeInCubic,
												dropShadowAmount: UNZOOM_SHADOW,
												y: stage.stageHeight + height,
												scaleX: scaleX / ZOOM_SCALE,
												scaleY: scaleY / ZOOM_SCALE,
												onUpdate: updateDropShadow,
												onComplete: dispose
												}
												
					 						: 	{
												time: Math.random() * ANIMATION_DURATION / 2 + ANIMATION_DURATION,
												transition: Equations.easeInCubic,
												y: stage.stageHeight + height,
												onComplete: dispose
												}
						);
		}
	
	//Dispose
	public function dispose():void
		{
		if	(isSelected)
			stage.dispatchEvent(new DropSwatchEvent(DropSwatchEvent.SELECT, null));
		
		momentumTimer.removeEventListener(TimerEvent.TIMER, momentumTimerEventHandler);
		momentumTimer.stop();
		momentumTimer = null;
			
		velocityTimer.removeEventListener(TimerEvent.TIMER, velocityTimerEventHandler);
		velocityTimer.stop();
		velocityTimer = null;		
		
		Tweener.removeTweens(this);
		
		stage.removeEventListener(DropSwatchEvent.SELECT, selectSwatchEventHandler);
		stage.removeEventListener(DropSwatchEvent.COLOR, updateSwatchColorEventHandler);
		stage.removeEventListener(DropSwatchEvent.TEXTURE, updateSwatchTextureEventHandler);
		stage.removeEventListener(DropSwatchEvent.REMOVE_ALL, removeAllSwatchesEventHandler);

		removeEventListener(Event.ENTER_FRAME, momentumTimerEventHandler);
		removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownEventHandler);
		removeEventListener(TransformGestureEvent.GESTURE_ZOOM , resizeGestureEventHandler);
		removeEventListener(TransformGestureEvent.GESTURE_ROTATE, rotateGestureEventHandler);
		
		stage.dispatchEvent(new DropSwatchEvent(DropSwatchEvent.DISPOSE, this));
		}
		
	//Override Get Bounds
	override public function getBounds(targetCoordinateSpace:DisplayObject):Rectangle
		{
		var bounds:Rectangle = super.getBounds(targetCoordinateSpace);
		
		if	(swatchTextureProperty != SwatchTexture.NONE)
			maskedBounds = new Rectangle(bounds.x + bounds.width / 4, bounds.y + bounds.height / 4, bounds.width / 2, bounds.height / 2);
			else
			maskedBounds = new Rectangle(bounds.x, bounds.y, bounds.width, bounds.height);
		
		return maskedBounds;
		}
		
	//Stage Bounds Setter
	public function updateStageBounds():void
		{
		stageBoundsProperty = new Rectangle(0, 0, stage.stageWidth, stage.stageHeight);
		}
		
	//Stage Bounds Getter
	public function get stageBounds():Rectangle
		{
		return stageBoundsProperty;
		}
	
	//Swatch Color Setter
	public function set swatchColor(value:uint):void
		{
		swatchColorProperty = value;
		}
		
	//Swatch Color Getter
	public function get swatchColor():uint
		{
		return swatchColorProperty;
		}
		
	//Swatch Size Setter
	public function set swatchSize(value:Number):void
		{
		swatchSizeProperty = value;
		}
		
	//Swatch Size Getter
	public function get swatchSize():Number
		{
		return swatchSizeProperty;
		}
		
	//Swatch Rotation Setter
	public function set swatchRotation(value:Number):void
		{
		swatchRotationProperty = value;
		}
		
	//Swatch Rotation Getter
	public function get swatchRotation():Number
		{
		return swatchRotationProperty;
		}
		
	//Swatch Texture Getter
	public function get swatchTexture():String
		{
		return swatchTextureProperty;
		}
		
	//Swatch Texture Rotation Getter
	public function get swatchTextureRotation():Number
		{
		return swatchTextureRotationProperty;
		}
		
	//Active Setter
	private function set isActive(value:Boolean):void
		{
		isActiveProperty = mouseEnabled = mouseChildren = value;
		}
		
	//Active Getter
	private function get isActive():Boolean
		{
		return isActiveProperty;
		}
	}
}