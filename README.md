<img src='https://trabits.nborzenko.me/icon6.svg' width='200' />

# Trabits - Track your habits!

Trabits is a habit tracker application.

It is available in the App Store https://apps.apple.com/app/id6478707901.

Promotional description is located at https://trabits.nborzenko.me/.

#### Key features of the application

- Personalized habit list
- Group by category
- Day targets and week goals
- Detailed statistics (by week, by month)
- Habit archiving
- Dark mode support

## Technical details

- The application is created with the combination of UIKit and SwiftUI.
- All user data is stored locally in CoreData, settings are stored in UserDefaults.
- The application supports light and dark modes and is accessible to a certain level.
- The application contains onboarding, a coordinator with UITabBarController, and some child coordinators.
- Data is mainly retrieved using several instances of NSFetchedResultsController.
- Depending on the UI framework data is presented using UICollectionView with UICollectionLayoutListConfiguration in UIKit or List in SwiftUI.
- Combine is used for some subscriptions.

## Screenshots

<img src='https://trabits.nborzenko.me/screenshots-light/tracker-large.png' width='200' />
<img src='https://trabits.nborzenko.me/screenshots-dark/weekly-detailed.png' width='200' />
<img src='https://trabits.nborzenko.me/screenshots-light/monthly.png' width='200' />
<img src='https://trabits.nborzenko.me/screenshots-dark/habit-editor.png' width='200' />
