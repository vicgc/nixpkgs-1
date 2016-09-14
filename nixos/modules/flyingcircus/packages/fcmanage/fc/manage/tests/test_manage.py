import fc.manage.manage as manage
import datetime


def test_dont_skip_unless_enc_present():
    assert manage.skip_production_update() is False


def test_dont_skip_on_nonproductive_node():
    manage.enc = { 'parameters': { 'production': False }}
    assert manage.skip_production_update() is False


def test_skip_production_on_daytime():
    manage.enc = { 'parameters': { 'production': True }}
    manage.now = datetime.datetime(2016, 9, 14, 12, 0)
    assert manage.skip_production_update() is True


def test_dont_skip_production_during_night():
    manage.enc = { 'parameters': { 'production': True }}
    manage.now = datetime.datetime(2016, 9, 14, 22, 4)
    assert manage.skip_production_update() is False
