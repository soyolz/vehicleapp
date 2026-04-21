#iOS Car Dealer Inventory App

A native iOS app built for the car dealership I work at. The app gives customers a fast, clean way to browse the dealership's live inventory directly from their phone, submit inquiry's on vehicles - (I plan on adding the feature to request schdeuling for services appointments etc from the app and many more).

---

## Background

This project started from a real problem. Customers visiting the dealership had questions about vehicles — pricing, mileage, specs — that required a salesperson to look things up manually. I saw an opportunity to build something that put that information directly in the customer's hands.

I approached my boss, got approval to build it, and used it as an opportunity to get hands-on experience with native iOS development — an area I wanted to grow in professionally.

---

## What it does

- Scrapes live inventory from 747motors.com and stores it locally on the device
- Syncs on launch — adds new vehicles, removes sold ones automatically
- Full detail view for each vehicle including photo gallery, specs, price, and monthly payment
- Search by make, model, year, VIN, or stock number
- Filter by body type, price range, mileage range, and fuel type
- Dark and light mode with persistent preference
- Update log tracking changes across versions

---

## Tech stack

| Technology | Purpose |
|---|---|
| Swift | Primary language |
| SwiftUI | User interface |
| SwiftData | On-device local storage |
| SwiftSoup | HTML scraping and parsing |
| Kingfisher | Image loading and disk caching |
| Xcode | IDE |

---

## Why I built this

I wanted real experience building a production iOS app — not a tutorial project, but something with actual users, real data, and genuine constraints.

The project gave me hands-on experience with the full iOS development cycle: data modeling, network requests, local persistence, UI architecture, performance optimization, and version control.

---

## Status

Active. Currently used internally. 

**Version 0.42**

---

## Author

Fritz Fils-Aime
