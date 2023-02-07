## 0.1.3
- chore: bump fluetooth to 0.0.5 ([#25](https://github.com/iandis/blue_print_pos/pull/23)) 

## 0.1.2
- feat: add printer feature ([#23](https://github.com/iandis/blue_print_pos/pull/23))

## 0.1.1
- fix: fix bluetooth permission on Android 12 ([#21](https://github.com/iandis/blue_print_pos/pull/21))

## 0.1.0
- **BREAKING CHANGE** refactor: change bluetooth package to use Fluetooth ([#19](https://github.com/iandis/blue_print_pos/pull/19))

## 0.0.23
- fix: add `await` to print processes 

## 0.0.22
- fix: empty section sublist and calculation ([#15](https://github.com/iandis/blue_print_pos/pull/13))

## 0.0.21
- fix: remove receipt vertical padding ([#13](https://github.com/iandis/blue_print_pos/pull/13))

## 0.0.20
- fix: batch print calculations ([#11](https://github.com/iandis/blue_print_pos/pull/11))

## 0.0.19
- feat: batch print ([#9](https://github.com/iandis/blue_print_pos/pull/9))

## 0.0.18
- chore: change `qr_flutter` from `pub`-hosted to `github`-hosted ([#7]((https://github.com/iandis/blue_print_pos/pull/7)))

## 0.0.17
- feat: adjustable font size on Android ([#5](https://github.com/iandis/blue_print_pos/pull/5))

## 0.0.16
- feat(receipt): add spacing using pixels ([#3](https://github.com/iandis/blue_print_pos/pull/3))

## 0.0.15

- fix(android): fix bitmap size on high density device ([#1](https://github.com/iandis/blue_print_pos/pull/1))

## 0.0.14

- feat: change [flutter_blue](https://pub.dev/packages/flutter_blue) with [flutter_blue_plus](https://pub.dev/packages/flutter_blue_plus) ([!53](https://github.com/andriyoganp/blue_print_pos/pull/53))
- fix: paper size print receipt text not pass bug ([#52](https://github.com/andriyoganp/blue_print_pos/pull/52))

## 0.0.13

- Update to flutter SDK 2.10.3, dart 2.16
- Change targetSDK to 32
- Fix NumberFormatException because null or empty
- Update log in debug only
- Fix CSS text-align in right

## 0.0.12

- Fix fail build on Android

## 0.0.11

- Provide default value on duration, only Android

## 0.0.10

- Set default duration delay in iOS
- Remove max width in method **.addImage**

## 0.0.9

- Add parameter **duration** for delay
- Add parameter **paperSize** to change paper width

## 0.0.8

- Add native code to convert content image

## 0.0.7

- Add parameter option to generate image as raster

## 0.0.6

- Add [webcontent_converter](https://pub.dev/packages/webcontent_converter) in library to make
  compatible in nullsafety

## 0.0.5

- Generate bytes with image raster enhancement

## 0.0.4

- Remove restriction service scanning iOS

## 0.0.3

- Decrease text small size into 0.8em

## 0.0.2

- Add documentation of code
- Add customization size for left-right text
- Change initialization with singleton

## 0.0.1

- Available print text, image, add new line, line dashed
- Support in Android and iOS
