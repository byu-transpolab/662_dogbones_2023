package org.matsim.project;

import org.apache.logging.log4j.Logger;
import org.matsim.api.core.v01.Coord;
import org.matsim.api.core.v01.Id;
import org.matsim.api.core.v01.Scenario;
import org.matsim.api.core.v01.population.*;
import org.matsim.core.utils.geometry.CoordUtils;
import org.matsim.core.utils.geometry.CoordinateTransformation;
import org.matsim.utils.objectattributes.attributable.Attributes;

import java.util.List;
import java.util.Map;
import java.util.Random;

public class PaysonPerson {

    String gender;
    Integer age;
    Boolean worker;
    Double workerprob = 0.42;
    Id<Person> id;
    String tourType;

    Scenario sc;
    PopulationFactory pf;
    CoordinateTransformation ct;

    // constructor method
    public PaysonPerson(String gender, Integer age){
        this.gender = gender;
        this.age = age;
    }

    public PaysonPerson(Integer id, Random r, Scenario sc, PopulationFactory pf,
                        CoordinateTransformation ct){
        this.id = Id.createPersonId(id);
        this.sc = sc;
        this.pf = pf;
        this.ct = ct;

        Boolean gendercoin = r.nextBoolean();
        if(gendercoin){
            this.gender = "female";
        } else {
            this.gender = "male";
        }

        if(r.nextDouble(0.0, 1.0) < workerprob){
            worker = true;
        } else {
            worker = false;
        }

        this.age = makeAge(r);

        // add to MATSim population
        Person mp = pf.createPerson(Id.createPersonId(id));
        mp.getAttributes().putAttribute("age", age);
        mp.getAttributes().putAttribute("gender", gender);
        mp.getAttributes().putAttribute("worker", worker);
        String myTourType = getTourType(this, r);
        makeTour(mp, myTourType, r);
        sc.getPopulation().addPerson(mp);
    }

    String getTourType(PaysonPerson p, Random r){
        Double tourProb = r.nextDouble(0.0, 1.0);
        if(p.worker){
            if(tourProb < 0.083){
                p.tourType = "Home";
            } else if (tourProb < 0.083 + 0.632) {
                p.tourType = "Mandatory";
            } else {
                p.tourType = "Discretionary";
            }
        } else {
            if(tourProb < 0.229){
                p.tourType = "Home";
            } else if (tourProb < 0.229 + 0.165) {
                p.tourType = "Mandatory";
            } else {
                p.tourType = "Discretionary";
            }
        }
        return p.tourType;
    }

    void makeTour(Person mp, String myTourType, Random r){
        Plan plan = pf.createPlan();
        Double homeX = r.nextGaussian(-111.7362,0.0135612);
        Double homeY = r.nextGaussian(40.03375, 0.0105619);
        Coord homeLocation = CoordUtils.createCoord(homeX, homeY);
        // everyone starts at home
        Activity homeStart = pf.createActivityFromCoord("Home", homeLocation);
        homeStart.setEndTime(6 * 3600);
        plan.addActivity(homeStart);
        Leg leg = pf.createLeg("car");
        plan.addLeg(leg);

        if (myTourType == "Mandatory") {
            makeMandatoryTour(plan, homeLocation, r);
        } else if (myTourType == "Discretionary") {
            makeDiscretionaryTour(plan, homeLocation, r);
        }

        Activity homeEnd = pf.createActivityFromCoord("Home", homeLocation);
        homeEnd.setEndTime(24*3600);
        plan.addActivity(homeEnd);

        mp.addPlan(plan);
        mp.setSelectedPlan(plan);
    }

    private void makeDiscretionaryTour(Plan plan, Coord homeLocation, Random r) {
        Integer numTrips = r.nextInt(2) + 1;

        double currentHour = 6; // Starting at 6 am
        double timevariable;

        for (Integer i = 1; i <= numTrips; i++) {
            // Code to add activity at random Payson location
            Coord destinationLocation = getRandomDestinationLocation(r);
            double startTime = getRandomStartTime(currentHour, r);

            // Create discretionary activity
            Activity discretionaryActivity = pf.createActivityFromCoord("Discretionary", destinationLocation);

            // Spend 3 hours at home and 1 hr at events
            discretionaryActivity.setEndTime(startTime + r.nextGaussian(3*3600,3600);
            plan.addActivity(discretionaryActivity);

            // Add leg between home and discretionary activity
            Leg legToDiscretionary = pf.createLeg("car");
            plan.addLeg(legToDiscretionary);

            timevariable = discretionaryActivity.getEndTime().seconds();

            // Update current hour for discretionary activity
            currentHour = (startTime / 3600) + (timevariable - startTime) / 3600;

            // Chance to return home between activities
            if (i < numTrips && shouldReturnHome(r, i)) {
                Activity returnHomeActivity = pf.createActivityFromCoord("Home", homeLocation);
                returnHomeActivity.setEndTime(currentHour * 3600 + r.nextGaussian(3600,60*15); // Randomizing return home activity duration (1-4 hours)
                plan.addActivity(returnHomeActivity);

                // Add leg between discretionary and home activity
                Leg legToHome = pf.createLeg("car");
                plan.addLeg(legToHome);

                // Update current hour for home activity
                timevariable = discretionaryActivity.getEndTime().seconds();

                // Update current hour for discretionary activity
                currentHour = (startTime / 3600) + (timevariable - startTime) / 3600;
            }

            // Update current hour for next activity
            currentHour += 2; // Assuming 2 hours for each activity
        }
    }

    private Coord getRandomDestinationLocation(Random r) {
        // Code to generate a random destination location around the mean coordinate
        // Use a normal distribution or any other distribution based on your requirements
        double destinationX = r.nextGaussian(-111.7362,0.0135612);
        double destinationY = r.nextGaussian(40.03375, 0.0105619);
        return CoordUtils.createCoord(destinationX, destinationY);
    }

    private double getRandomStartTime(double currentHour, Random r) {
        // Code to generate a random start time within the specified time window
        double startTimeWindow = 2 * 3600; // 2 hours time window
        return currentHour * 3600 + r.nextDouble(startTimeWindow);
    }

    private boolean shouldReturnHome(Random r, int numTripsDone) {
        // Determine the probability of returning home based on the number of trips done
        if (numTripsDone == 1) {
            return r.nextDouble() < 0.5; // 50% probability for one trip
        } else if (numTripsDone == 2) {
            return r.nextDouble() < 0.8; // 80% probability for two consecutive trips
        } else {
            return r.nextDouble() < 0.99; // 99% probability for three consecutive trips
        }
    }

    private void makeMandatoryTour(Plan plan, Coord homeLocation, Random r) {
        Coord nbWorkLoc = CoordUtils.createCoord(-111.6833027, 40.1037746);
        Coord sbWorkLoc = CoordUtils.createCoord(-111.7934400, 39.9599421);
        Coord workLocation;
        if(r.nextDouble(0.0, 1.0) < 0.05) {
            workLocation = sbWorkLoc;
        } else {
            workLocation = nbWorkLoc;
        }

        // make work activity (including time)

        // make a discretionary activity on the way home sometimes

        // go home

    }

    private Integer makeAge(Random r){
        Integer top = r.nextInt(60);
        return top + 20;
    }

    public void printInfo(){
        System.out.println("Person: " + this.id);
        System.out.println("age: " + this.age);
        System.out.println("gender: " + this.gender);
        System.out.println("worker: " + this.worker);

    }

}
