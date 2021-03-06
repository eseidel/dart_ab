// Copyright 2012 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

library MixerDemo;

import 'dart:collection';
import 'dart:html';
import 'dart:js' as js;
import 'dart:math' as math;
import 'package:box2d/box2d_browser.dart';
import 'demo.dart';

class MixerTest extends Demo {

  final FixtureDef _ballFixture;
  final math.Random _rnd;
  final List<Body> _bouncers = new List<Body>();
  final SplayTreeMap<int, int> _counts = new SplayTreeMap<int, int>();

  int _fastFrameCount = 0;

  MixerTest(this._ballFixture)
      : _rnd = new math.Random(),
        super("Mixer test", new Vector2(0.0, -30.0), 5.0);


  @override
  void initialize() {
    var sd = new PolygonShape();
    sd.setAsBox(50.0, 0.4);

    var bd = new BodyDef();
    bd.position.setValues(0.0, 0.0);
    assert (world != null);

    //
    // Rotating thing
    //
    var numPieces = 6;
    var radius = 50;
    bd = new BodyDef()
        ..type = BodyType.DYNAMIC;
    var body = world.createBody(bd);

    for (int i = 0; i < numPieces; i++) {
      var angle = 2 * math.PI * (i / numPieces.toDouble());

      var xPos = radius * math.cos(angle);
      var yPos = radius * math.sin(angle);

      var cd = new PolygonShape();
      cd.setAsBoxWithCenterAndAngle(1.0, 30.0, new Vector2(xPos, yPos), angle);

      var fd = new FixtureDef()
          ..shape = cd
          ..density = 10.0
          ..friction = 0.0
          ..restitution = 0.0;

      body.createFixture(fd);
    }

    body.bullet = false;

    // Create an empty ground body.
    var bodyDef = new BodyDef();
    var groundBody = world.createBody(bodyDef);

    var rjd = new RevoluteJointDef()
        ..initialize(body, groundBody, body.position)
        ..motorSpeed = 0.8
        ..maxMotorTorque = 100000000.0
        ..enableMotor = true;

    world.createJoint(rjd);
  }

  @override
  void step(num timeStamp) {
    super.step(timeStamp);

    var avgFrame = super.avgStepTime;

    if (avgFrame < 7000) {
      _fastFrameCount++;
    } else if (avgFrame > 8000) {
      _fastFrameCount = 0;
      if (_bouncers.length > 1) {
        world.destroyBody(_bouncers.removeAt(0));
      }
    }

    if(_fastFrameCount > 5) {
      _fastFrameCount = 0;
      _addItem();
    }

    ctx.fillStyle = 'black';
    ctx.font = '30px Arial';
    ctx.textAlign = 'right';
    ctx.fillText('${_bouncers.length} items', 150, 30);

    var deltaInt = elapsedUs ~/ 1000;
    var current = _counts[deltaInt];
    if(current == null) current = 0;
    _counts[deltaInt] = current + 1;
  }

  void _addItem() {
    var bd2 = new BodyDef()
        ..type = BodyType.DYNAMIC
        ..position = new Vector2(0.0, 40.0)
        ..linearVelocity = new Vector2(35.0, 0.0);

    var ball = world.createBody(bd2)
        ..createFixture(_ballFixture);

    _bouncers.add(ball);
  }


  void _doStats() {
    var data = [];
    var totalFrames = 0;
    _counts.forEach((k, v) {
      data.add(new js.JsArray.from([k, v]));
      totalFrames += v;
    });

    print("Total frames: $totalFrames");

    var windowContext = new js.JsObject.fromBrowserObject(window);

    var jsData = new js.JsArray.from(data);

    windowContext['_chartData'] = jsData;

    js.context.callMethod('updateChart');
  }
}

void main() {
  var psd = new CircleShape()
      ..radius = 1.0;

  var ballFixtureDef = new FixtureDef()
      ..shape = psd
      ..density = 10.0
      ..friction = 0.9
      ..restitution = 0.95;

  var mixer = new MixerTest(ballFixtureDef)
      ..initialize()
      ..initializeAnimation()
      ..runAnimation();

  var button = querySelector('#chart_button') as ButtonElement;
  button.onClick.listen((_) => mixer._doStats());
}
