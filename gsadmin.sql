-- GearShare schema + demo seed.
--
-- Demo data: 20 Croatian accounts, 72 listings (about 75% in Zagreb, the rest in
-- Split, Rijeka, Zadar, Osijek and Vukovar) and 20 reservations. Person names are
-- Croatian; every product name and description is in English.
--
-- Listing photos live in the BACKEND repo under item_images/, profile photos under
-- profile_images/, and both are baked into the container by the Dockerfile - Render's
-- filesystem is ephemeral, so anything merely uploaded is lost on the next redeploy.
--
-- This file is NOT idempotent. To reload an existing database, run drop_all.sql first.
SET client_encoding = 'UTF8';

-- 1. Table: account (Independent)
CREATE TABLE account (
    account_id SERIAL PRIMARY KEY,
    oauth2_id VARCHAR(100) UNIQUE,
    user_email VARCHAR(255) NOT NULL UNIQUE,
    user_first_name VARCHAR(50),
    user_last_name VARCHAR(50),
    user_contact VARCHAR(255),
    user_contact_email VARCHAR(255) UNIQUE,
    user_location VARCHAR(255),
    registration_date DATE NOT NULL DEFAULT CURRENT_DATE,
    profile_image_path VARCHAR(255),
    account_role VARCHAR(20) NOT NULL CHECK (account_role IN ('trader', 'buyer', 'admin')),
    account_rating DECIMAL(2, 1)
);

---

-- 2. Table: itemtype (Independent)
CREATE TABLE itemtype (
  itemtype_id SERIAL PRIMARY KEY,
  itemtype_name character varying
);

---

-- 3. Table: reservation (Deferred FK to advertisement)
CREATE TABLE reservation (
    reservation_id SERIAL PRIMARY KEY,

    reservation_start DATE NOT NULL,
    reservation_end DATE NOT NULL,

    reservation_request_started TIMESTAMPTZ NOT NULL,
    reservation_request_ended TIMESTAMPTZ,
    reservation_grade INT,

    buyer_id INT,
    FOREIGN KEY (buyer_id) REFERENCES account(account_id) ON DELETE SET NULL,

    advertisement_id INT -- Column for the FK (Constraint added later)
);

---

-- 4. Table: advertisement (Deferred FK to reservation)
CREATE TABLE advertisement (
    advertisement_id SERIAL PRIMARY KEY,
    advertisement_price DECIMAL(10, 2),
    advertisement_deposit DECIMAL(10, 2),
    advertisement_location_takeover VARCHAR(255),
    advertisement_location_return VARCHAR(255),
    advertisement_start DATE NOT NULL,
    advertisement_end DATE NOT NULL,

    advertisement_location_takeover_latitude DECIMAL(10, 5),
    advertisement_location_takeover_longitude DECIMAL(10, 5),

    advertisement_location_return_latitude DECIMAL(10, 6),
    advertisement_location_return_longitude DECIMAL(10, 6),


    trader_id INT NOT NULL,
    FOREIGN KEY (trader_id) REFERENCES account(account_id) ON DELETE CASCADE,

    itemtype_id INT,
    FOREIGN KEY (itemtype_id) REFERENCES itemtype(itemtype_id),

    item_name VARCHAR(255),
    item_description TEXT,
    item_image_path VARCHAR(255) UNIQUE
);

---


-- Add the Foreign Key from reservation to advertisement
ALTER TABLE reservation
ADD CONSTRAINT fk_advertisement
    FOREIGN KEY (advertisement_id)
    REFERENCES advertisement(advertisement_id)
    ON DELETE SET NULL;



---
CREATE OR REPLACE FUNCTION check_trader_role()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM account
        WHERE account_id = NEW.trader_id
        AND account_role = 'trader'
    ) THEN
        RAISE EXCEPTION 'User ID % does not have trader role. Only traders can create advertisements.', NEW.trader_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trg_check_trader_role
BEFORE INSERT OR UPDATE ON advertisement
FOR EACH ROW EXECUTE FUNCTION check_trader_role();

-- 20 demo accounts: 12 traders, 6 buyers, 2 admins.
-- Account 6 is the site owner - see DEPLOYMENT_PLAN step 3.
INSERT INTO account (oauth2_id, user_email, user_first_name, user_last_name, user_contact, user_contact_email, user_location, registration_date, profile_image_path, account_role, account_rating) VALUES
('1', 'ivan.horvat@example.com', 'Ivan', 'Horvat', '+385 91 234 5671', 'ivan.horvat@example.com', 'Zagreb', '2024-12-06', '/profile_images/profile1.jpg', 'trader', 4.8),--  1 (trader)
('2', 'petra.kovacevic@example.com', 'Petra', 'Kovačević', '+385 98 145 2280', 'petra.kovacevic@example.com', 'Zagreb', '2025-01-30', '/profile_images/profile2.jpg', 'trader', 4.9),--  2 (trader)
('3', 'luka.babic@example.com', 'Luka', 'Babić', '+385 95 771 3094', 'luka.babic@example.com', 'Zagreb', '2024-10-20', '/profile_images/profile3.jpg', 'trader', 4.6),--  3 (trader)
('4', 'ana.juric@example.com', 'Ana', 'Jurić', '+385 91 508 6612', 'ana.juric@example.com', 'Zagreb', '2024-07-26', '/profile_images/profile4.jpg', 'trader', 5.0),--  4 (trader)
('5', 'marko.novak@example.com', 'Marko', 'Novak', '+385 99 214 7735', 'marko.novak@example.com', 'Split', '2025-11-21', '/profile_images/profile5.jpg', 'trader', 4.7),--  5 (trader)
('6', 'replace-me@example.com', 'Site', 'Owner', '+385 91 000 0000', 'owner.contact@example.com', 'Zagreb', '2025-06-02', NULL, 'admin', NULL),           --  6 (admin)
('7', 'nina.kovac@example.com', 'Nina', 'Kovač', '+385 92 337 1148', 'nina.kovac@example.com', 'Zagreb', '2024-06-01', '/profile_images/profile7.jpg', 'admin', NULL),--  7 (admin)
('8', 'domagoj.peric@example.com', 'Domagoj', 'Perić', '+385 98 620 4419', 'domagoj.peric@example.com', 'Zagreb', '2025-02-26', '/profile_images/profile8.jpg', 'trader', 4.5),--  8 (trader)
('9', 'iva.maric@example.com', 'Iva', 'Marić', '+385 95 118 8302', 'iva.maric@example.com', 'Rijeka', '2024-05-06', '/profile_images/profile9.jpg', 'trader', 4.8),--  9 (trader)
('10', 'tomislav.vukovic@example.com', 'Tomislav', 'Vuković', '+385 91 447 9051', 'tomislav.vukovic@example.com', 'Zagreb', '2025-10-25', '/profile_images/profile10.jpg', 'trader', 4.4),-- 10 (trader)
('11', 'katarina.saric@example.com', 'Katarina', 'Šarić', '+385 99 803 2276', 'katarina.saric@example.com', 'Zadar', '2025-04-02', '/profile_images/profile11.jpg', 'trader', 4.9),-- 11 (trader)
('12', 'filip.blazevic@example.com', 'Filip', 'Blažević', '+385 98 559 6134', 'filip.blazevic@example.com', 'Zagreb', '2026-02-01', '/profile_images/profile12.jpg', 'trader', 4.6),-- 12 (trader)
('13', 'maja.radic@example.com', 'Maja', 'Radić', '+385 91 762 0488', 'maja.radic@example.com', 'Osijek', '2026-03-21', '/profile_images/profile13.jpg', 'trader', 4.7),-- 13 (trader)
('14', 'josip.tomic@example.com', 'Josip', 'Tomić', '+385 95 390 4517', 'josip.tomic@example.com', 'Zagreb', '2025-12-25', NULL, 'trader', 4.2),          -- 14 (trader)
('15', 'lucija.pavlovic@example.com', 'Lucija', 'Pavlović', '+385 98 271 6690', 'lucija.pavlovic@example.com', 'Zagreb', '2024-04-10', '/profile_images/profile15.jpg', 'buyer', 4.9),-- 15 (buyer)
('16', 'ante.matic@example.com', 'Ante', 'Matić', '+385 91 634 8825', 'ante.matic@example.com', 'Zagreb', '2025-11-06', NULL, 'buyer', NULL),             -- 16 (buyer)
('17', 'dora.knezevic@example.com', 'Dora', 'Knežević', '+385 99 456 1173', 'dora.knezevic@example.com', 'Zagreb', '2024-10-06', '/profile_images/profile17.jpg', 'buyer', 4.8),-- 17 (buyer)
('18', 'nikola.bozic@example.com', 'Nikola', 'Božić', '+385 95 902 3348', 'nikola.bozic@example.com', 'Split', '2025-06-18', '/profile_images/profile18.jpg', 'buyer', 4.6),-- 18 (buyer)
('19', 'marta.grgic@example.com', 'Marta', 'Grgić', '+385 91 185 7762', 'marta.grgic@example.com', 'Zagreb', '2025-07-14', NULL, 'buyer', NULL),          -- 19 (buyer)
('20', 'petar.vidovic@example.com', 'Petar', 'Vidović', '+385 98 344 0916', 'petar.vidovic@example.com', 'Vukovar', '2026-03-12', NULL, 'buyer', NULL);   -- 20 (buyer)


INSERT INTO itemtype (itemtype_name) VALUES
('Skis'),                   -- 1
('Snowboard'),              -- 2
('Climbing Gear'),          -- 3
('Camping Equipment'),      -- 4
('Cycling Gear'),           -- 5
('Water Sports'),           -- 6
('Hiking Gear'),            -- 7
('Winter Sports'),          -- 8
('Mountain Equipment');     -- 9


-- 72 listings. Every one is available today and runs into 2027, so no search
-- filtered by date can come back empty.
INSERT INTO advertisement (
    advertisement_price, advertisement_deposit,
    advertisement_location_takeover, advertisement_location_return,
    advertisement_start, advertisement_end,
    trader_id, itemtype_id, item_name, item_description, item_image_path,
    advertisement_location_takeover_latitude, advertisement_location_takeover_longitude,
    advertisement_location_return_latitude, advertisement_location_return_longitude
) VALUES
(26.00, 150.00, 'Sljeme, Medvednica', 'Sljeme, Medvednica', '2025-09-06', '2027-04-07', 1, 1, 'All-Mountain Skis 170cm', 'Versatile 170cm all-mountain skis with adjustable bindings. Freshly serviced and waxed before every rental.', '/item_images/item1.jpg', 45.8992, 15.9639, 45.8992, 15.9639),-- 1
(19.00, 90.00, 'Črnomerec, Zagreb', 'Črnomerec, Zagreb', '2025-09-11', '2027-04-14', 1, 1, 'Beginner Ski Set with Boots', 'Soft-flex skis, poles and boots in sizes 38-44. Everything a first-timer needs for a weekend on Sljeme.', '/item_images/item2.jpg', 45.8203, 15.9375, 45.8203, 15.9375),-- 2
(23.50, 120.00, 'Medveščak, Zagreb', 'Medveščak, Zagreb', '2025-09-16', '2027-04-21', 1, 1, 'Carving Skis 165cm with Poles', 'Narrow-waisted 165cm carving skis for groomed pistes. Includes matching poles and a padded ski bag.', '/item_images/item3.jpg', 45.8283, 15.9789, 45.8283, 15.9789),-- 3
(34.00, 200.00, 'Sljeme, Medvednica', 'Sljeme, Medvednica', '2025-09-21', '2027-04-28', 1, 1, 'Ski Touring Setup with Skins', 'Lightweight touring skis with pin bindings and pre-cut climbing skins. Boots available in EU 41-45.', '/item_images/item4.jpg', 45.8992, 15.9639, 45.8992, 15.9639),-- 4
(21.00, 100.00, 'Maksimir, Zagreb', 'Maksimir, Zagreb', '2025-09-26', '2027-05-05', 2, 1, 'Cross-country Ski Set', 'Classic-style cross-country skis with boots and poles. Ideal for the tracks around Maksimir and Jarun.', '/item_images/item5.jpg', 45.8228, 16.0186, 45.8228, 16.0186),-- 5
(15.00, 70.00, 'Britanski trg, Zagreb', 'Britanski trg, Zagreb', '2025-10-01', '2027-05-12', 2, 1, 'Junior Ski Package 130cm', 'Complete junior package: 130cm skis, helmet and boots in EU 32-36. Perfect for kids aged 8-12.', '/item_images/item6.jpg', 45.8121, 15.9669, 45.8121, 15.9669),-- 6
(38.00, 240.00, 'Sljeme, Medvednica', 'Sljeme, Medvednica', '2025-10-06', '2027-05-19', 2, 1, 'Freeride Powder Skis 186cm', 'Wide 110mm underfoot powder skis for deep days. Mounted with freeride bindings, DIN 5-13.', '/item_images/item7.jpg', 45.8992, 15.9639, 45.8992, 15.9639),-- 7
(32.00, 190.00, 'Črnomerec, Zagreb', 'Črnomerec, Zagreb', '2025-10-11', '2027-05-26', 2, 1, 'Race Carving Skis with Race Boots', 'Stiff GS-style race skis for confident skiers, paired with 110-flex race boots in EU 42-44.', '/item_images/item8.jpg', 45.8203, 15.9375, 45.8203, 15.9375),-- 8
(22.00, 110.00, 'Medveščak, Zagreb', 'Medveščak, Zagreb', '2025-10-16', '2027-06-02', 2, 2, 'All-Mountain Snowboard 156cm', 'Directional twin 156cm board with medium flex. Suits riders 65-85kg on piste and in light powder.', '/item_images/item9.jpg', 45.8283, 15.9789, 45.8283, 15.9789),-- 9
(24.00, 120.00, 'Kvaternikov trg, Zagreb', 'Kvaternikov trg, Zagreb', '2025-10-21', '2027-06-09', 2, 2, 'Freestyle Twin-Tip Snowboard', 'True twin park board with a soft flex, ideal for rails, boxes and first jumps in the snowpark.', '/item_images/item10.jpg', 45.8146, 15.9994, 45.8146, 15.9994),-- 10
(16.50, 80.00, 'Trešnjevka, Zagreb', 'Trešnjevka, Zagreb', '2025-10-26', '2027-06-16', 2, 2, 'Snowboard Boots and Bindings Set', 'Boa-lacing boots in EU 39-46 with matching bindings. Rent alongside a board or on their own.', '/item_images/item11.jpg', 45.8032, 15.9414, 45.8032, 15.9414),-- 11
(41.00, 260.00, 'Sljeme, Medvednica', 'Sljeme, Medvednica', '2025-10-31', '2027-06-23', 3, 2, 'Splitboard Touring Setup', 'Splitboard with skins, pucks and collapsible poles for earning your turns away from the lifts.', '/item_images/item12.jpg', 45.8992, 15.9639, 45.8992, 15.9639),-- 12
(18.00, 85.00, 'Špansko, Zagreb', 'Špansko, Zagreb', '2025-11-05', '2027-06-30', 3, 2, 'Beginner Snowboard Package', 'Forgiving 148-152cm board with soft boots and a helmet. Includes a 20-minute handover briefing.', '/item_images/item13.jpg', 45.7986, 15.9083, 45.7986, 15.9083),-- 13
(29.00, 170.00, 'Sljeme, Medvednica', 'Sljeme, Medvednica', '2025-11-10', '2027-07-07', 3, 2, 'Powder Snowboard 162cm', 'Tapered 162cm powder board with a rockered nose. Floats beautifully on the deepest days.', '/item_images/item14.jpg', 45.8992, 15.9639, 45.8992, 15.9639),-- 14
(17.00, 90.00, 'Britanski trg, Zagreb', 'Britanski trg, Zagreb', '2025-11-15', '2027-07-14', 4, 3, '60m Dynamic Climbing Rope', '60m 9.8mm UIAA-certified dynamic rope with a dry treatment. Logged and inspected after every rental.', '/item_images/item15.jpg', 45.8121, 15.9669, 45.8121, 15.9669),-- 15
(45.00, 350.00, 'Medveščak, Zagreb', 'Medveščak, Zagreb', '2025-11-20', '2027-07-21', 4, 3, 'Full Trad Climbing Rack', 'Complete trad rack: cams from 0.3 to 4, a full set of nuts, slings and 14 alpine draws.', '/item_images/item16.jpg', 45.8283, 15.9789, 45.8283, 15.9789),-- 16
(14.00, 65.00, 'Kvaternikov trg, Zagreb', 'Kvaternikov trg, Zagreb', '2025-11-25', '2027-07-28', 4, 3, 'Climbing Harness and Belay Kit', 'Adjustable harness in S-XL with an assisted-braking belay device, locking carabiner and chalk bag.', '/item_images/item17.jpg', 45.8146, 15.9994, 45.8146, 15.9994),-- 17
(20.00, 130.00, 'Trešnjevka, Zagreb', 'Trešnjevka, Zagreb', '2025-11-30', '2027-08-04', 4, 3, 'Bouldering Crash Pad', 'Large taco-fold crash pad, 132 x 100cm open. Carries as a backpack with padded shoulder straps.', '/item_images/item18.jpg', 45.8032, 15.9414, 45.8032, 15.9414),-- 18
(11.00, 55.00, 'Britanski trg, Zagreb', 'Britanski trg, Zagreb', '2025-12-05', '2027-08-11', 4, 3, 'Climbing Shoes Set (EU 38-45)', 'Eight pairs of neutral all-day climbing shoes, EU 38 to 45. Disinfected between every rental.', '/item_images/item19.jpg', 45.8121, 15.9669, 45.8121, 15.9669),-- 19
(16.00, 85.00, 'Sljeme, Medvednica', 'Sljeme, Medvednica', '2025-12-10', '2027-08-18', 4, 3, 'Via Ferrata Set with Helmet', 'Certified via ferrata lanyard with energy absorber, harness and helmet. Sized for adults and teens.', '/item_images/item20.jpg', 45.8992, 15.9639, 45.8992, 15.9639),-- 20
(27.00, 180.00, 'Medveščak, Zagreb', 'Medveščak, Zagreb', '2025-12-15', '2027-08-25', 4, 3, 'Ice Axes and Crampons', 'Pair of technical ice axes with 12-point steel crampons. Fits B2 and B3 mountaineering boots.', '/item_images/item21.jpg', 45.8283, 15.9789, 45.8283, 15.9789),-- 21
(12.50, 70.00, 'Ravnice, Zagreb', 'Ravnice, Zagreb', '2025-12-20', '2027-09-01', 8, 3, 'Quickdraw Set (12 pcs)', 'Twelve 17cm sport-climbing quickdraws with keylock carabiners, plus two extendable alpine draws.', '/item_images/item22.jpg', 45.8228, 16.0044, 45.8228, 16.0044),-- 22
(22.00, 130.00, 'Dubrava, Zagreb', 'Dubrava, Zagreb', '2025-12-25', '2027-09-08', 10, 4, '4-Season 2-Person Tent', 'Geodesic 2-person tent rated for winter use. 4000mm flysheet, taped seams and a snow valance.', '/item_images/item23.jpg', 45.8317, 16.0483, 45.8317, 16.0483),-- 23
(28.00, 160.00, 'Sesvete, Zagreb', 'Sesvete, Zagreb', '2025-12-30', '2027-09-15', 10, 4, 'Family Camping Tent (4 persons)', 'Tunnel tent with two sleeping pods and a standing-height living area. Pitches in under 15 minutes.', '/item_images/item24.jpg', 45.83, 16.1128, 45.83, 16.1128),-- 24
(9.00, 40.00, 'Borongaj, Zagreb', 'Borongaj, Zagreb', '2026-01-04', '2027-09-22', 10, 4, 'Camping Stove with Gas Canister', 'Compact two-burner gas stove with wind shields. One full canister included, spares available.', '/item_images/item25.jpg', 45.8175, 16.0325, 45.8175, 16.0325),-- 25
(13.00, 60.00, 'Dubrava, Zagreb', 'Dubrava, Zagreb', '2026-01-09', '2027-09-29', 10, 4, 'Complete Camping Cook Set', 'Nesting pots, pans, kettle and cutlery for four people, plus a folding washing-up bowl.', '/item_images/item26.jpg', 45.8317, 16.0483, 45.8317, 16.0483),-- 26
(15.00, 75.00, 'Utrine, Novi Zagreb', 'Utrine, Novi Zagreb', '2026-01-14', '2027-10-06', 10, 4, 'Sleeping Bag -10°C', 'Synthetic mummy bag with a -10°C comfort rating. Washed and re-lofted after every rental.', '/item_images/item27.jpg', 45.7728, 15.9781, 45.7728, 15.9781),-- 27
(8.50, 35.00, 'Travno, Novi Zagreb', 'Travno, Novi Zagreb', '2026-01-19', '2027-10-13', 3, 4, 'Self-Inflating Sleeping Mat', '7cm self-inflating mat with an R-value of 4.2. Packs down to the size of a two-litre bottle.', '/item_images/item28.jpg', 45.7683, 15.9861, 45.7683, 15.9861),-- 28
(10.00, 45.00, 'Vukovar', 'Vukovar', '2026-01-24', '2027-10-20', 13, 4, 'Camping Hammock with Mosquito Net', 'Parachute-nylon hammock with an integrated mosquito net, tree straps and a compact rain tarp.', '/item_images/item29.jpg', 45.3511, 18.9976, 45.3511, 18.9976),-- 29
(12.00, 55.00, 'Sesvete, Zagreb', 'Sesvete, Zagreb', '2025-09-01', '2027-10-27', 10, 4, 'Folding Camping Chairs (set of 4)', 'Four padded folding chairs with cup holders and carry bags. Rated to 120kg each.', '/item_images/item30.jpg', 45.83, 16.1128, 45.83, 16.1128),-- 30
(11.50, 50.00, 'Tvrđa, Osijek', 'Tvrđa, Osijek', '2025-09-06', '2027-11-03', 13, 4, 'Camping Table and Lantern Kit', 'Height-adjustable aluminium table for four, with two rechargeable LED lanterns and a power bank.', '/item_images/item31.jpg', 45.5606, 18.6939, 45.5606, 18.6939),-- 31
(10.50, 45.00, 'Borongaj, Zagreb', 'Borongaj, Zagreb', '2025-09-11', '2027-11-10', 10, 4, '48L Cooler Box', '48-litre hard cooler that holds ice for up to three days. Includes four reusable freezer blocks.', '/item_images/item32.jpg', 45.8175, 16.0325, 45.8175, 16.0325),-- 32
(30.00, 200.00, 'Maksimir, Zagreb', 'Maksimir, Zagreb', '2025-09-16', '2027-11-17', 12, 5, 'Full-Suspension Mountain Bike 27.5"', 'Trail bike with 140mm travel front and rear, dropper post and hydraulic disc brakes. Frame size M/L.', '/item_images/item33.jpg', 45.8228, 16.0186, 45.8228, 16.0186),-- 33
(35.00, 250.00, 'Trg bana Jelačića, Zagreb', 'Trg bana Jelačića, Zagreb', '2025-09-21', '2027-11-24', 12, 5, 'Carbon Road Bike 54cm', 'Carbon endurance road bike, 54cm frame, 2x11 groupset and 25mm tyres. Pedals your choice.', '/item_images/item34.jpg', 45.8131, 15.9775, 45.8131, 15.9775),-- 34
(24.00, 180.00, 'Vukovar', 'Vukovar', '2025-09-26', '2027-12-01', 13, 5, 'Electric City Bike with Pedal Assist', 'Step-through e-bike with a 500Wh battery, good for roughly 80km. Charger and two locks included.', '/item_images/item35.jpg', 45.3511, 18.9976, 45.3511, 18.9976),-- 35
(27.00, 190.00, 'Trsat, Rijeka', 'Trsat, Rijeka', '2025-10-01', '2027-12-08', 9, 5, 'Gravel Bike 56cm', 'Alloy gravel bike with 40mm tyres, 1x11 gearing and mounts for bikepacking bags. 56cm frame.', '/item_images/item36.jpg', 45.3283, 14.4589, 45.3283, 14.4589),-- 36
(14.00, 80.00, 'Borik, Zadar', 'Borik, Zadar', '2025-10-06', '2027-12-15', 11, 5, 'City Bike with Basket and Lock', 'Comfortable seven-speed city bike with a front basket, mudguards, lights and a heavy-duty D-lock.', '/item_images/item37.jpg', 44.13, 15.22, 44.13, 15.22),-- 37
(11.00, 60.00, 'Vrbani, Zagreb', 'Vrbani, Zagreb', '2025-10-11', '2027-12-22', 12, 5, 'Kids Bike 20" with Helmet', '20-inch children''s bike with a matching helmet. Suits riders roughly 120-140cm tall.', '/item_images/item38.jpg', 45.7943, 15.9256, 45.7943, 15.9256),-- 38
(13.50, 90.00, 'Knežija, Zagreb', 'Knežija, Zagreb', '2025-10-16', '2027-12-29', 12, 5, 'Bike Trailer for Children', 'Two-seat bike trailer that converts to a stroller. Five-point harnesses and a rain cover included.', '/item_images/item39.jpg', 45.7967, 15.9469, 45.7967, 15.9469),-- 39
(12.00, 100.00, 'Stenjevec, Zagreb', 'Stenjevec, Zagreb', '2025-10-21', '2027-04-05', 12, 5, 'Roof Bike Rack (2 bikes)', 'Pair of lockable roof-mounted bike carriers with fitting keys. Fits most factory roof bars.', '/item_images/item40.jpg', 45.8081, 15.8878, 45.8081, 15.8878),-- 40
(16.00, 120.00, 'Savica, Zagreb', 'Savica, Zagreb', '2025-10-26', '2027-04-12', 12, 5, 'Turbo Trainer with Cadence Sensor', 'Direct-drive turbo trainer with a cadence sensor and ANT+/Bluetooth. Cassette fitted, 11-speed.', '/item_images/item41.jpg', 45.7989, 16.0117, 45.7989, 16.0117),-- 41
(20.00, 140.00, 'Gornji grad, Osijek', 'Gornji grad, Osijek', '2025-10-31', '2027-04-19', 13, 5, 'Touring Bike with Panniers', 'Steel touring bike with a rear rack and two 20-litre waterproof panniers. Built for long, flat days.', '/item_images/item42.jpg', 45.555, 18.6955, 45.555, 18.6955),-- 42
(23.00, 140.00, 'Poluotok, Zadar', 'Poluotok, Zadar', '2025-11-05', '2027-04-26', 11, 6, 'Inflatable SUP Board with Paddle', '10''6" inflatable stand-up paddleboard with a three-piece paddle, pump, leash and backpack.', '/item_images/item43.jpg', 44.1156, 15.2264, 44.1156, 15.2264),-- 43
(29.00, 180.00, 'Žnjan, Split', 'Žnjan, Split', '2025-11-10', '2027-05-03', 5, 6, 'Rigid SUP with Carbon Paddle', 'Hard-shell touring SUP that tracks far better than an inflatable, with a light carbon paddle.', '/item_images/item44.jpg', 43.5, 16.475, 43.5, 16.475),-- 44
(26.00, 160.00, 'Bačvice, Split', 'Bačvice, Split', '2025-11-15', '2027-05-10', 5, 6, 'Single Sea Kayak', 'Sit-in sea kayak with a spray deck, buoyancy aid and a two-piece paddle. Dry bag included.', '/item_images/item45.jpg', 43.5028, 16.4525, 43.5028, 16.4525),-- 45
(33.00, 220.00, 'Kantrida, Rijeka', 'Kantrida, Rijeka', '2025-11-20', '2027-05-17', 9, 6, 'Double Sea Kayak with Spray Decks', 'Tandem sea kayak with two spray decks, two buoyancy aids and a rudder for windy crossings.', '/item_images/item46.jpg', 45.3306, 14.3856, 45.3306, 14.3856),-- 46
(21.00, 130.00, 'Tvrđa, Osijek', 'Tvrđa, Osijek', '2025-11-25', '2027-05-24', 13, 6, '2-Person Canoe', 'Stable open canoe for two, perfect for the Drava and Danube. Paddles and buoyancy aids included.', '/item_images/item47.jpg', 45.5606, 18.6939, 45.5606, 18.6939),-- 47
(15.00, 70.00, 'Bačvice, Split', 'Bačvice, Split', '2025-11-30', '2027-05-31', 5, 6, 'Wetsuit 5/4mm (M and L)', 'Two 5/4mm sealed-seam wetsuits in M and L. Rinsed in fresh water and dried after every rental.', '/item_images/item48.jpg', 43.5028, 16.4525, 43.5028, 16.4525),-- 48
(9.50, 40.00, 'Riva, Split', 'Riva, Split', '2025-12-05', '2027-06-07', 5, 6, 'Snorkelling Set with Fins', 'Tempered-glass mask, dry snorkel and open-heel fins in EU 38-45. Mesh carry bag included.', '/item_images/item49.jpg', 43.5081, 16.4402, 43.5081, 16.4402),-- 49
(37.00, 250.00, 'Korzo, Rijeka', 'Korzo, Rijeka', '2025-12-10', '2027-06-14', 9, 6, 'Windsurf Board and Rig', '145-litre freeride board with a 5.5m rig, mast, boom and harness. Suits beginner to intermediate.', '/item_images/item50.jpg', 45.3271, 14.4422, 45.3271, 14.4422),-- 50
(48.00, 400.00, 'Žnjan, Split', 'Žnjan, Split', '2025-12-15', '2027-06-21', 5, 6, 'Scuba Set: BCD, Regulator, Tanks', 'Complete scuba kit: BCD, serviced regulator, dive computer and two 12-litre tanks. Certification required.', '/item_images/item51.jpg', 43.5, 16.475, 43.5, 16.475),-- 51
(19.00, 110.00, 'Jarun, Zagreb', 'Jarun, Zagreb', '2025-12-20', '2027-06-28', 14, 6, 'Inflatable Kayak with Pump', 'Two-person drop-stitch inflatable kayak. Inflates in ten minutes and fits in a car boot.', '/item_images/item52.jpg', 45.7828, 15.9186, 45.7828, 15.9186),-- 52
(14.00, 70.00, 'Korzo, Rijeka', 'Korzo, Rijeka', '2025-12-25', '2027-07-05', 9, 7, '65L Trekking Backpack', '65-litre trekking pack with an adjustable back system, rain cover and a detachable daypack lid.', '/item_images/item53.jpg', 45.3271, 14.4422, 45.3271, 14.4422),-- 53
(8.00, 35.00, 'Borik, Zadar', 'Borik, Zadar', '2025-12-30', '2027-07-12', 11, 7, '25L Daypack with Hydration', '25-litre daypack with a two-litre hydration bladder, walking-pole loops and a rain cover.', '/item_images/item54.jpg', 44.13, 15.22, 44.13, 15.22),-- 54
(10.00, 50.00, 'Trsat, Rijeka', 'Trsat, Rijeka', '2026-01-04', '2027-07-19', 9, 7, 'Waterproof Hiking Boots EU 42', 'Mid-cut waterproof hiking boots in EU 42, broken in and treated. Two pairs of merino socks included.', '/item_images/item55.jpg', 45.3283, 14.4589, 45.3283, 14.4589),-- 55
(7.00, 30.00, 'Podsused, Zagreb', 'Podsused, Zagreb', '2026-01-09', '2027-07-26', 14, 7, 'Adjustable Trekking Poles', 'Pair of three-section aluminium trekking poles with cork grips, plus snow and mud baskets.', '/item_images/item56.jpg', 45.8156, 15.87, 45.8156, 15.87),-- 56
(12.00, 60.00, 'Gajnice, Zagreb', 'Gajnice, Zagreb', '2026-01-14', '2027-08-02', 14, 7, '3-Layer Waterproof Shell Jacket', '20k/20k three-layer hardshell in sizes S-XL. Pit zips, helmet-compatible hood, fully taped seams.', '/item_images/item57.jpg', 45.8181, 15.89, 45.8181, 15.89),-- 57
(13.00, 90.00, 'Zapruđe, Novi Zagreb', 'Zapruđe, Novi Zagreb', '2026-01-19', '2027-08-09', 14, 7, 'Handheld GPS with Topo Maps', 'Rugged handheld GPS preloaded with Croatian topographic maps. 20-hour battery and spare AAs.', '/item_images/item58.jpg', 45.7797, 15.9931, 45.7797, 15.9931),-- 58
(13.50, 65.00, 'Sljeme, Medvednica', 'Sljeme, Medvednica', '2026-01-24', '2027-08-16', 3, 7, 'Snowshoes with Poles', 'Pair of aluminium-frame snowshoes with heel lifts and telescopic poles. Rated to 120kg.', '/item_images/item59.jpg', 45.8992, 15.9639, 45.8992, 15.9639),-- 59
(6.50, 30.00, 'Trg bana Jelačića, Zagreb', 'Trg bana Jelačića, Zagreb', '2025-09-01', '2027-08-23', 14, 7, 'Headlamp Set (3 units)', 'Three 400-lumen rechargeable headlamps with red night mode. Fully charged at handover.', '/item_images/item60.jpg', 45.8131, 15.9775, 45.8131, 15.9775),-- 60
(9.00, 40.00, 'Vrbani, Zagreb', 'Vrbani, Zagreb', '2025-09-06', '2027-08-30', 14, 7, 'Water Filter and Hydration System', 'Gravity water filter rated for 1500 litres, plus two three-litre reservoirs and spare hoses.', '/item_images/item61.jpg', 45.7943, 15.9256, 45.7943, 15.9256),-- 61
(8.00, 35.00, 'Utrine, Novi Zagreb', 'Utrine, Novi Zagreb', '2025-09-11', '2027-09-06', 8, 7, 'First Aid and Emergency Bivvy Kit', 'Comprehensive outdoor first-aid kit with a SAM splint, two emergency bivvy bags and a whistle.', '/item_images/item62.jpg', 45.7728, 15.9781, 45.7728, 15.9781),-- 62
(42.00, 280.00, 'Črnomerec, Zagreb', 'Črnomerec, Zagreb', '2025-09-16', '2027-09-13', 1, 8, 'Complete Winter Kit: Skis, Boots, Helmet', 'Everything for a ski week in one rental: skis, boots, poles, helmet and goggles. Sized on collection.', '/item_images/item63.jpg', 45.8203, 15.9375, 45.8203, 15.9375),-- 63
(11.00, 55.00, 'Britanski trg, Zagreb', 'Britanski trg, Zagreb', '2025-09-21', '2027-09-20', 1, 8, 'Ski Helmet and Goggles Set', 'Certified ski helmet in S/M/L with photochromic goggles. Fresh liner fitted before each rental.', '/item_images/item64.jpg', 45.8121, 15.9669, 45.8121, 15.9669),-- 64
(7.50, 30.00, 'Maksimir, Zagreb', 'Maksimir, Zagreb', '2025-09-26', '2027-09-27', 3, 8, 'Sledges and Snow Tubes (set of 3)', 'Two steerable sledges and one inflatable snow tube, with a hand pump. A guaranteed hit with kids.', '/item_images/item65.jpg', 45.8228, 16.0186, 45.8228, 16.0186),-- 65
(9.50, 45.00, 'Ravnice, Zagreb', 'Ravnice, Zagreb', '2025-10-01', '2027-10-04', 3, 8, 'Ice Skates (EU 36-44)', 'Six pairs of recreational ice skates, EU 36-44, freshly sharpened. Guards and a carry bag included.', '/item_images/item66.jpg', 45.8228, 16.0044, 45.8228, 16.0044),-- 66
(14.00, 90.00, 'Sljeme, Medvednica', 'Sljeme, Medvednica', '2025-10-06', '2027-10-11', 1, 8, 'Ski Boot Rental Set (EU 36-46)', 'Boots only, in every size from EU 36 to 46. Heat-moulded on collection and sanitised after each rental.', '/item_images/item67.jpg', 45.8992, 15.9639, 45.8992, 15.9639),-- 67
(18.00, 110.00, 'Medveščak, Zagreb', 'Medveščak, Zagreb', '2025-10-11', '2027-10-18', 8, 9, 'Expedition Backpack 85L', '85-litre expedition pack with a reinforced hip belt, ice-axe loops and a removable lid.', '/item_images/item68.jpg', 45.8283, 15.9789, 45.8283, 15.9789),-- 68
(25.00, 200.00, 'Špansko, Zagreb', 'Špansko, Zagreb', '2025-10-16', '2027-10-25', 8, 9, 'Portable Solar Power Station', '500Wh power station with AC, USB-C and 12V outputs, plus a 100W folding solar panel.', '/item_images/item69.jpg', 45.7986, 15.9083, 45.7986, 15.9083),-- 69
(17.00, 100.00, 'Sljeme, Medvednica', 'Sljeme, Medvednica', '2025-10-21', '2027-11-01', 8, 9, 'Mountaineering Boots EU 43', 'B2 crampon-compatible mountaineering boots in EU 43, insulated for winter alpine routes.', '/item_images/item70.jpg', 45.8992, 15.9639, 45.8992, 15.9639),-- 70
(20.00, 140.00, 'Stenjevec, Zagreb', 'Stenjevec, Zagreb', '2025-10-26', '2027-11-08', 8, 9, '4-Season Bivy Tent', 'Single-wall two-person bivy tent that pitches on a ledge. 1.9kg packed, built for exposed camps.', '/item_images/item71.jpg', 45.8081, 15.8878, 45.8081, 15.8878),-- 71
(22.00, 190.00, 'Sesvete, Zagreb', 'Sesvete, Zagreb', '2025-10-31', '2027-11-15', 8, 9, 'Satellite Communicator and Beacon', 'Two-way satellite messenger with SOS, plus a registered personal locator beacon. Airtime included.', '/item_images/item72.jpg', 45.83, 16.1128, 45.83, 16.1128);-- 72


-- Migration script for Stripe Connect implementation
-- This creates a separate mapping table for Account ID to Stripe Connect Account ID

-- Create the stripe_connect_account mapping table
CREATE TABLE IF NOT EXISTS stripe_connect_account (
    stripe_connect_account_id SERIAL PRIMARY KEY,
    account_id INTEGER NOT NULL UNIQUE,
    stripe_account_id VARCHAR(255) NOT NULL UNIQUE,
    account_status VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (account_id) REFERENCES account(account_id) ON DELETE CASCADE
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_stripe_connect_account_id ON stripe_connect_account(account_id);
CREATE INDEX IF NOT EXISTS idx_stripe_account_id ON stripe_connect_account(stripe_account_id);

-- Optional: If you had existing data in account table, you would migrate it here
-- INSERT INTO stripe_connect_account (account_id, stripe_account_id, account_status)
-- SELECT account_id, stripe_connect_account_id, stripe_account_status
-- FROM account
-- WHERE stripe_connect_account_id IS NOT NULL;
CREATE TABLE payment (
    payment_id SERIAL PRIMARY KEY,
    payer_id INT NOT NULL,
    payment_description VARCHAR(255),
    payment_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP, -- Added for better tracking

    FOREIGN KEY (payer_id) REFERENCES account(account_id) ON DELETE SET NULL
);

-- 2. Table: report
-- Allows users to report other users (e.g., for bad behavior or scams)
CREATE TABLE report (
    report_id SERIAL PRIMARY KEY,
    reporter_id INT NOT NULL,  -- The user filing the report
    reported_id INT NOT NULL,  -- The user being reported
    report_details TEXT,
    report_status VARCHAR(20) DEFAULT 'pending' CHECK (report_status IN ('pending', 'reviewed', 'resolved', 'dismissed')),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (reporter_id) REFERENCES account(account_id) ON DELETE CASCADE,
    FOREIGN KEY (reported_id) REFERENCES account(account_id) ON DELETE CASCADE
);

INSERT INTO payment (payer_id, payment_description) VALUES
(15, 'Rental payment - All-Mountain Skis 170cm (Sljeme)'),
(15, 'Security deposit - All-Mountain Skis 170cm'),
(16, 'Rental payment - 4-Season 2-Person Tent (Dubrava, Zagreb)'),
(17, 'Rental payment - Full-Suspension Mountain Bike (Maksimir, Zagreb)'),
(18, 'Rental payment - Single Sea Kayak (Bacvice, Split)'),
(19, 'Rental payment - 65L Trekking Backpack (Korzo, Rijeka)'),
(20, 'Late return fee - All-Mountain Snowboard 156cm'),
(17, 'Security deposit - Family Camping Tent (Sesvete, Zagreb)');


INSERT INTO report (reporter_id, reported_id, report_details, report_status) VALUES
(16, 10, 'The tent description said it was fully waterproof, but the flysheet leaked on the first night.', 'pending'),
(19, 9, 'Trader arrived 40 minutes late for the handover in Rijeka and did not answer the phone.', 'reviewed'),
(1, 20, 'Skis were returned with deep scratches along the base that were not there at handover.', 'resolved'),
(4, 16, 'Renter cancelled an hour before pickup and refused to cover the cancellation fee.', 'dismissed'),
(6, 14, 'Multiple listings from this account use the same photo. Flagged for review.', 'pending');


CREATE TABLE subscription_price (
    price INTEGER NOT NULL
);

INSERT INTO subscription_price (price) VALUES (100000);

-- FIX

ALTER TABLE reservation DROP CONSTRAINT reservation_buyer_id_fkey;
ALTER TABLE reservation ADD CONSTRAINT reservation_buyer_id_fkey
    FOREIGN KEY (buyer_id) REFERENCES account(account_id) ON DELETE CASCADE;

ALTER TABLE payment DROP CONSTRAINT payment_payer_id_fkey;
ALTER TABLE payment ADD CONSTRAINT payment_payer_id_fkey
    FOREIGN KEY (payer_id) REFERENCES account(account_id) ON DELETE CASCADE;



ALTER TABLE reservation DROP CONSTRAINT fk_advertisement;
ALTER TABLE reservation ADD CONSTRAINT fk_advertisement
    FOREIGN KEY (advertisement_id) REFERENCES advertisement(advertisement_id) ON DELETE CASCADE;

ALTER TABLE reservation
ADD CONSTRAINT unique_advertisement_buyer
UNIQUE (advertisement_id, buyer_id);

-- Add check constraints for date validation

-- For reservation table: reservation_start must be <= reservation_end
ALTER TABLE reservation
ADD CONSTRAINT check_reservation_dates
CHECK (reservation_start <= reservation_end);

-- For advertisement table: advertisement_start must be <= advertisement_end
ALTER TABLE advertisement
ADD CONSTRAINT check_advertisement_dates
CHECK (advertisement_start <= advertisement_end);

-- Rental history: 12 completed, 3 in progress, 5 upcoming. Inserted last, so the
-- unique and date constraints above are already in force.
--
-- reservation_request_ended MUST stay non-NULL on every row that has already ended:
-- ReservationSchedulerService.processEndedReservations() runs at 00:00 Europe/Zagreb
-- and files an 'AUTOMATIC REPORT' for each ended reservation still left open.
INSERT INTO reservation (reservation_start, reservation_end, reservation_request_started, reservation_request_ended, reservation_grade, buyer_id, advertisement_id) VALUES
('2026-02-06', '2026-02-13', '2026-02-03 09:00:00+02', '2026-02-14 18:30:00+02', 5, 15, 1),
('2026-05-01', '2026-05-05', '2026-04-10 09:00:00+02', '2026-05-06 18:30:00+02', 4, 16, 23),
('2026-06-12', '2026-06-15', '2026-06-03 09:00:00+02', '2026-06-16 18:30:00+02', 5, 17, 33),
('2026-07-03', '2026-07-10', '2026-06-12 09:00:00+02', '2026-07-11 18:30:00+02', 5, 18, 45),
('2026-04-18', '2026-04-25', '2026-04-07 09:00:00+02', '2026-04-26 18:30:00+02', 4, 19, 53),
('2026-01-23', '2026-01-30', '2026-01-18 09:00:00+02', '2026-01-31 18:30:00+02', 3, 20, 9),
('2026-06-27', '2026-06-29', '2026-06-11 09:00:00+02', '2026-06-30 18:30:00+02', 5, 15, 37),
('2026-07-17', '2026-07-20', '2026-06-28 09:00:00+02', '2026-07-21 18:30:00+02', 4, 16, 47),
('2026-05-22', '2026-05-26', '2026-05-13 09:00:00+02', '2026-05-27 18:30:00+02', 5, 17, 24),
('2026-03-07', '2026-03-14', '2026-02-22 09:00:00+02', '2026-03-15 18:30:00+02', 4, 19, 63),
('2026-08-01', '2026-08-06', '2026-07-29 09:00:00+02', '2026-08-07 18:30:00+02', 5, 18, 44),
('2026-06-05', '2026-06-07', '2026-05-30 09:00:00+02', '2026-06-08 18:30:00+02', 4, 12, 34),
('2026-08-15', '2026-08-22', '2026-08-09 10:15:00+02', NULL, NULL, 17, 43),
('2026-08-18', '2026-08-25', '2026-08-12 10:15:00+02', NULL, NULL, 16, 30),
('2026-08-14', '2026-08-21', '2026-08-04 10:15:00+02', NULL, NULL, 20, 52),
('2026-08-29', '2026-09-05', '2026-08-14 14:40:00+02', NULL, NULL, 15, 46),
('2026-09-04', '2026-09-11', '2026-08-12 14:40:00+02', NULL, NULL, 19, 25),
('2026-09-12', '2026-09-19', '2026-08-14 14:40:00+02', NULL, NULL, 18, 36),
('2026-10-02', '2026-10-09', '2026-08-16 14:40:00+02', NULL, NULL, 16, 68),
('2026-12-27', '2027-01-03', '2026-08-14 14:40:00+02', NULL, NULL, 17, 5);
