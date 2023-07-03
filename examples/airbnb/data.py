from datetime import datetime, timedelta
from typing import List

import click
from schema import Booking, City, Country, Host, Place, Review, User, Room, Hotel
from sqlalchemy.orm import sessionmaker

from pgsync.base import pg_engine, subtransactions
from pgsync.helper import teardown
from pgsync.utils import config_loader, get_config


@click.command()
@click.option(
    "--config",
    "-c",
    help="Schema config",
    type=click.Path(exists=True),
)
def main(config):
    config: str = get_config(config)
    teardown(drop_db=False, config=config)
    document: dict = next(config_loader(config))
    database: str = document.get("database", document["index"])
    with pg_engine(database) as engine:
        Session = sessionmaker(bind=engine, autoflush=True)
        session = Session()

        users: List[User] = [
            User(email="stephanie.miller@aol.com"),
            User(email="nancy.gaines@ibm.com"),
            User(email="andrea.cabrera@gmail.com"),
            User(email="brandon86@yahoo.com"),
            User(email="traci.williams@amazon.com"),
            User(email="john.brown@apple.com"),
            #may29th2023--test1 of changes--1line--
            User(email="testemailchange1@apple.com"),
            #June5th2023--test2 of changes--1line--
            User(email="testemailchange2@netflix.com"),
        ]

        hosts: List[Host] = [
            Host(email="kermit@muppet-labs.inc", description="d1", category="category1"),
            Host(email="bert@sesame.street", description="d2", category="category2"),
            Host(email="big.bird@sesame.street", description="d3", category="category3"),
            Host(email="cookie.monster@sesame.street", description="d4", category="category4"),
            Host(email="mr.snuffleupagus@sesame.street", description="d5", category="category5"),
            Host(email="grover@sesame.street", description="d6", category="category6"),
            Host(email="miss.piggy@muppet-labs.inc", description="d7", category="category7"),
        ]
        
        rooms: List[Room] = [
            Room(email="suite1@muppet-labs.inc", description="d1", category="category1"),
            Room(email="roofhouse@sesame.street", description="d2", category="category2"),
            Room(email="regualr@sesame.street", description="d3", category="category3"),
            Room(email="couples@sesame.street", description="d4", category="category4"),
            Room(email="modern@sesame.street", description="d5", category="category5"),
            Room(email="families@sesame.street", description="d6", category="category6"),
            Room(email="deluxe@muppet-labs.inc", description="d7", category="category7"),
        ] 
        
        hotels: List[Hotel] = [
            Hotel(email="hotel1@muppet-labs.inc", description="4star", category="category1"),
            Hotel(email="hotel2@sesame.street", description="5star", category="category2"),
            Hotel(email="hotel3@sesame.street", description="exclusive", category="category3"),
            Hotel(email="hotel4@sesame.street", description="goverments", category="category4"),
            Hotel(email="hotel5@sesame.street", description="resort", category="category5"),
            Hotel(email="hotel6@sesame.street", description="summer", category="category6"),
            Hotel(email="hotel7@muppet-labs.inc", description="winter", category="category7"),
        ] 
        

        cities: List[City] = [
            City(
                name="Manila",
                country=Country(
                    name="Philippines",
                    country_code="PH",
                ),
            ),
            City(
                name="Lisbon",
                country=Country(
                    name="Portugal",
                    country_code="PT",
                ),
            ),
            City(
                name="Havana",
                country=Country(
                    name="Cuba",
                    country_code="CU",
                ),
            ),
            City(
                name="Copenhagen",
                country=Country(
                    name="Denmark",
                    country_code="DK",
                ),
            ),
            City(
                name="London",
                country=Country(
                    name="United Kingdom",
                    country_code="UK",
                ),
            ),
            City(
                name="Casablanca",
                country=Country(
                    name="Morocco",
                    country_code="MA",
                ),
            ),
        ]

        places: List[Place] = [
            Place(
                host=hosts[0],
                city=cities[0],
                room=rooms[0],
                hotel=hotels[0],
                address="Quezon Boulevard",
            ),
            Place(
                host=hosts[1],
                city=cities[1],
                room=rooms[1],
                hotel=hotels[1],
                address="Castelo de São Jorge",
            ),
            Place(
                host=hosts[2],
                city=cities[2],
                room=rooms[2],
                hotel=hotels[2],
                address="Old Havana",
            ),
            Place(
                host=hosts[3],
                city=cities[3],
                room=rooms[3],
                hotel=hotels[3],
                address="Tivoli Gardens",
            ),
            Place(
                host=hosts[4],
                city=cities[4],
                room=rooms[4],
                hotel=hotels[4],
                address="Buckingham Palace",
            ),
            Place(
                host=hosts[5],
                city=cities[5],
                room=rooms[5],
                hotel=hotels[5],
                address="Medina",
            ),
        ]

        reviews: List[Review] = [
            Review(
                booking=Booking(
                    user=users[0],
                    place=places[0],
                    start_date=datetime.now() + timedelta(days=1),
                    end_date=datetime.now() + timedelta(days=4),
                    price_per_night=100,
                    num_nights=4,
                ),
                rating=1,
                review_body="The rooms were left in a tolerable state",
            ),
            Review(
                booking=Booking(
                    user=users[1],
                    place=places[1],
                    start_date=datetime.now() + timedelta(days=2),
                    end_date=datetime.now() + timedelta(days=4),
                    price_per_night=150,
                    num_nights=3,
                ),
                rating=2,
                review_body="I found my place wonderfully taken care of",
            ),
            Review(
                booking=Booking(
                    user=users[2],
                    place=places[2],
                    start_date=datetime.now() + timedelta(days=15),
                    end_date=datetime.now() + timedelta(days=19),
                    price_per_night=120,
                    num_nights=4,
                ),
                rating=3,
                review_body="All of my house rules were respected",
            ),
            Review(
                booking=Booking(
                    user=users[3],
                    place=places[3],
                    start_date=datetime.now() + timedelta(days=2),
                    end_date=datetime.now() + timedelta(days=7),
                    price_per_night=300,
                    num_nights=5,
                ),
                rating=4,
                review_body="Such a pleasure to host and welcome these guests",
            ),
            Review(
                booking=Booking(
                    user=users[4],
                    place=places[4],
                    start_date=datetime.now() + timedelta(days=1),
                    end_date=datetime.now() + timedelta(days=10),
                    price_per_night=800,
                    num_nights=3,
                ),
                rating=5,
                review_body="We would be happy to host them again",
            ),
            Review(
                booking=Booking(
                    user=users[5],
                    place=places[5],
                    start_date=datetime.now() + timedelta(days=2),
                    end_date=datetime.now() + timedelta(days=8),
                    price_per_night=80,
                    num_nights=10,
                ),
                rating=3,
                review_body="Please do not visit our town ever again!",
            ),
        ]

        with subtransactions(session):
            session.add_all(users)
            session.add_all(hosts)
            session.add_all(rooms)
            session.add_all(hotels)
            session.add_all(cities)
            session.add_all(places)
            session.add_all(reviews)


if __name__ == "__main__":
    main()
