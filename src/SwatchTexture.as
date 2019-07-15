package
{
//Imports
import com.caurina.transitions.Equations;
import com.caurina.transitions.Tweener;
import com.mattie.utils.ConstantsUtil;
import flash.display.BlendMode;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Loader;
import flash.display.PixelSnapping;
import flash.display.Shape;
import flash.display.Sprite;
import flash.events.Event;
import flash.geom.Matrix;
import flash.net.URLRequest;
import flash.utils.getDefinitionByName;

//Class
public class SwatchTexture extends Sprite
	{
	//Constants
	public static const NONE:String = "none";
	public static const PAPER:String = "Paper";
	public static const SLATE:String = "Slate";
	public static const STRIPE:String = "Stripe";
	public static const WOOD:String = "Wood";
	
	private static const ANIMATION_DURATION:Number = 0.5;
	
	//Properties
	private var textureProperty:String;
	private var textureRotationProperty:Number;
	private var isAnimatingProperty:Boolean;
	private var rotatable:Boolean;
	
	//Variables
	public static var previousSwatchTexture:String;
	public static var previousSwatchTextureRotation:Number;
	
	private static var texturesArray:Array;
	private static var rotationsArray:Array;
	
	private var size:Number;
	private var textureCanvas:Sprite;
	private var textureMask:Shape;
	private var textureBitmap:BitmapData;
	private var animateRotation:Boolean; 
	
	//Constructor
	public function SwatchTexture(size:Number, rotatable:Boolean = true)
		{
		this.size = size;
		this.rotatable = rotatable;
		
		init();
		}
		
	//Initialization
	private function init():void
		{
		textureMask = new Shape();
		textureMask.graphics.beginFill(0x00FF00, 1.0);
		textureMask.graphics.drawRect(-size / 2, -size / 2, size, size);
		textureMask.graphics.endFill();
		
		textureCanvas = new Sprite();
		textureCanvas.mask = textureMask;
		
		addChild(textureMask);
		addChild(textureCanvas);
		}

	//Draw Texture
	private function drawTexture(textureName:String, isVisible:Boolean):Shape
		{
		var result:Shape = new Shape();
		
		if	(textureName != NONE)
			{
			var classReference:Class = getDefinitionByName(textureName) as Class;
			textureBitmap = new classReference as BitmapData;
			
			var centerMatrix:Matrix = new Matrix();
			centerMatrix.translate(-textureBitmap.width / 2, -textureBitmap.height / 2);
	
			result.graphics.beginBitmapFill(textureBitmap, centerMatrix, false, true);
			result.graphics.drawRect(-textureBitmap.width / 2, -textureBitmap.height / 2, textureBitmap.width, textureBitmap.height);
			result.graphics.endFill();
			
			if	(rotatable)
				{
				var leftMatrix:Matrix = new Matrix();
				leftMatrix.scale(-1, 1);
				leftMatrix.translate(-textureBitmap.width / 2, -textureBitmap.height / 2);
				
				result.graphics.beginBitmapFill(textureBitmap, leftMatrix, false, true);
				result.graphics.drawRect(-textureBitmap.width, -textureBitmap.height / 2, textureBitmap.width / 2, textureBitmap.height);
				result.graphics.endFill();
				
				var topMatrix:Matrix = new Matrix();
				topMatrix.scale(1, -1);
				topMatrix.translate(-textureBitmap.width / 2, -textureBitmap.height / 2);
				
				result.graphics.beginBitmapFill(textureBitmap, topMatrix, false, true);
				result.graphics.drawRect(-textureBitmap.width / 2, -textureBitmap.height, textureBitmap.width, textureBitmap.height / 2);
				result.graphics.endFill();
				
				var rightMatrix:Matrix = new Matrix();
				rightMatrix.scale(-1, 1);
				rightMatrix.translate(textureBitmap.width / 2 + textureBitmap.width, -textureBitmap.height / 2);
				
				result.graphics.beginBitmapFill(textureBitmap, rightMatrix, false, true);
				result.graphics.drawRect(textureBitmap.width / 2, -textureBitmap.height / 2, textureBitmap.width / 2, textureBitmap.height);
				result.graphics.endFill();
				
				var bottomMatrix:Matrix = new Matrix();
				bottomMatrix.scale(1, -1);
				bottomMatrix.translate(-textureBitmap.width / 2, textureBitmap.height / 2 + textureBitmap.height);
				
				result.graphics.beginBitmapFill(textureBitmap, bottomMatrix, false, true);
				result.graphics.drawRect(-textureBitmap.width / 2, textureBitmap.height / 2, textureBitmap.width, textureBitmap.height / 2);
				result.graphics.endFill();
				}
			
			result.scaleX = result.scaleY = 100 / (textureBitmap.width / size) * 0.01;
			result.blendMode = BlendMode.MULTIPLY;
			
			(isVisible) ? result.alpha = 1.0 : result.alpha = 0.0;
			}
		
		return result;
		}
		
	//Texture Setter
	public function set texture(value:String):void
		{
		if	(!ConstantsUtil.classHasPublicConstant(SwatchTexture, value))
			throw new ArgumentError("SwatchTexture: \"set texture(value:String)\" – value parameter does not exist as class constant.");
		
		if	(textureProperty != value && !isAnimatingProperty)
			{
			if	(textureCanvas.numChildren == 0)
				textureCanvas.addChild(drawTexture(value, true));
				else
				{
				isAnimatingProperty = true;
				
				textureCanvas.addChild(drawTexture(value, false));
				
				var newTexture:Shape = textureCanvas.getChildAt(1) as Shape;
				newTexture.rotation = textureRotationProperty;
				
				var oldTexture:Shape = textureCanvas.getChildAt(0) as Shape;
				
				Tweener.addTween(newTexture, {time: ANIMATION_DURATION, transition: Equations.easeInOutCubic, alpha: 1.0});
				Tweener.addTween(oldTexture, {time: ANIMATION_DURATION, transition: Equations.easeInOutCubic, alpha: 0.0, onComplete: setTextureCompleteHandler});
				
				previousSwatchTexture = value;
				}
				
			textureProperty = value;
			}
		}

	//Set Texture Complete Event Handler
	private function setTextureCompleteHandler():void
		{
		textureCanvas.removeChildAt(0);
		isAnimatingProperty = false;
		}
		
	//Texture Getter
	public function get texture():String
		{
		return textureProperty;
		}
		
	//Random Texture Getter
	public static function get randomTexture():String
		{
		if	(texturesArray == null)
			texturesArray = ConstantsUtil.classPublicConstantsArray(SwatchTexture);

		return texturesArray[Math.round(Math.random() * (texturesArray.length - 1))];
		}
		
	//Texture Rotation Setter
	public function set textureRotation(value:Number):void
		{
		if	(!isAnimatingProperty && textureCanvas.numChildren != 0)
			{
			if	(!animateRotation)
				{
				textureRotationProperty = Shape(textureCanvas.getChildAt(0)).rotation = value;
				animateRotation = true;
				}
				else
				{
				isAnimatingProperty = true;
				Tweener.addTween(Shape(textureCanvas.getChildAt(0)), {time: ANIMATION_DURATION, transition: Equations.easeInOutCubic, rotation: value, onComplete: setTextureRotationCompleteHandler});
				previousSwatchTextureRotation = value;
				}
			}
		}
		
	//Set Texture Rotation Complete Event Handler
	private function setTextureRotationCompleteHandler():void
		{
		textureRotationProperty = Shape(textureCanvas.getChildAt(0)).rotation;
		isAnimatingProperty = false;
		}

	//Texture Rotation Getter
	public function get textureRotation():Number
		{
		return textureRotationProperty;
		}
		
	//Random Texture Rotation Getter
	public static function get randomTextureRotation():uint
		{
		if	(rotationsArray == null)
			rotationsArray = new Array(0.0, 90.0, 180.0, 270.0)
			
		return rotationsArray[Math.round(Math.random() * (rotationsArray.length - 1))];
		}
		
	//isAnimating Getter
	public function get isAnimating():Boolean
		{
		return isAnimatingProperty;
		}
	}
}