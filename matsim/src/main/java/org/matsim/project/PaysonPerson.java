package org.matsim.project;

import org.matsim.api.core.v01.Coord;
import org.matsim.api.core.v01.Id;
import org.matsim.api.core.v01.Scenario;
import org.matsim.api.core.v01.population.*;
import org.matsim.core.utils.geometry.CoordUtils;
import org.matsim.core.utils.geometry.CoordinateTransformation;

import java.util.Random;

public class PaysonPerson {

    String gender;
    Integer age;
    Boolean worker;
    Double workerprob = 0.42;
    Id<Person> id;

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

        Boolean genderCoin = r.nextBoolean();
        if(genderCoin){
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

        Person p = pf.createPerson(Id.createPersonId(id));
        String tourType = getTourType(worker, r);
        makeTour(p, tourType, r);

        // add to MATSim population
        p.getAttributes().putAttribute("age", age);
        p.getAttributes().putAttribute("gender", gender);
        p.getAttributes().putAttribute("worker", worker);
        p.getAttributes().putAttribute("tourType", tourType);

        sc.getPopulation().addPerson(p);
    }

    String getTourType(Boolean worker, Random r){
        Double tourProb = r.nextDouble(0.0, 1.0);
        String tourType;
        if(worker){
            if(tourProb < 0.083){
                tourType = "Home";
            } else if (tourProb < 0.083 + 0.632) {
                tourType = "Mandatory";
            } else {
                tourType = "Discretionary";
            }
        } else {
            if(tourProb < 0.229){
                tourType = "Home";
            } else if (tourProb < 0.229 + 0.165) {
                tourType = "Mandatory";
            } else {
                tourType = "Discretionary";
            }
        }
        return tourType;
    }

    void makeTour(Person p, String tourType, Random r){
        Plan plan = pf.createPlan();
        Double homeX = r.nextGaussian(-111.7362,0.0135612);
        Double homeY = r.nextGaussian(40.03375, 0.0105619);
        Coord homeLocation = CoordUtils.createCoord(homeX, homeY);

        // everyone starts at home
        Activity homeStart = pf.createActivityFromCoord("Home", homeLocation);
        homeStart.setEndTime(6*3600);
        plan.addActivity(homeStart);
        Leg leg = pf.createLeg("car");
        plan.addLeg(leg);

        if (tourType == "Mandatory") {
            makeMandatoryTour(plan, r);
        } else if (tourType == "Discretionary") {
            makeDiscretionaryTour(plan, homeLocation, r);
        }

        // everyone ends at home
        Activity homeEnd = pf.createActivityFromCoord("Home", homeLocation);
        homeEnd.setEndTime(24*3600);
        plan.addActivity(homeEnd);

        p.addPlan(plan);
        p.setSelectedPlan(plan);
    }

    private void makeDiscretionaryTour(Plan plan, Coord homeLocation, Random r) {
        // Make between 1 and 3 trips
        Integer numTrips = r.nextInt(2) + 1;

        Double dayStart = 6.0*3600; // 6 AM
        Double dayEnd = 22.0*3600; // 10 PM
        Double currentTime = dayStart;
        int consecutiveTrips = 0;

        for (Integer i = 1; i <= numTrips; i++) {


            Coord destinationLocation = getRandomDestinationLocation(r);
            Double startTime = getRandomTime(currentTime, r, 3600*0.5, (dayEnd - currentTime));
            Double endTime = getRandomTime(startTime, r, 3600*0.5, Math.min(3600*3.0, (dayEnd - currentTime)));
            if(endTime > dayEnd) endTime = dayEnd;

            Activity discretionaryActivity = pf.createActivityFromCoord("Discretionary", destinationLocation);
            discretionaryActivity.setStartTime(startTime);
            discretionaryActivity.setEndTime(endTime);
            plan.addActivity(discretionaryActivity);
            consecutiveTrips++;

            Leg legToDiscretionary = pf.createLeg("car");
            plan.addLeg(legToDiscretionary);

            currentTime = endTime;

            if(currentTime + (3600*0.6) >= dayEnd) break; // Don't make more activities if close to end of day

            // Chance to return home between activities
            if (i < numTrips && shouldReturnHome(r, consecutiveTrips)) {
                // Reset consecutive trips
                consecutiveTrips = 0;

                // Make home activity
                Activity returnHomeActivity = pf.createActivityFromCoord("Home", homeLocation);

                startTime = getRandomTime(currentTime, r, 3600*0.5, (dayEnd - currentTime));
                endTime = getRandomTime(startTime, r, 3600*0.5, Math.min(3600*3.0, (dayEnd - currentTime)));
                if(endTime > dayEnd) endTime = dayEnd;

                returnHomeActivity.setStartTime(startTime);
                returnHomeActivity.setEndTime(endTime);
                plan.addActivity(returnHomeActivity);

                // Add leg between discretionary and home activity
                Leg legToHome = pf.createLeg("car");
                plan.addLeg(legToHome);

                currentTime = endTime;

                if(currentTime + (3600*0.6) >= dayEnd) break; // Don't make more activities if close to end of day
            }
        }
    }

    private Coord getRandomDestinationLocation(Random r) {
        // Code to generate a random destination location around the mean coordinate
        // Use a normal distribution or any other distribution based on your requirements
        double destinationX = r.nextGaussian(-111.7362,0.0135612);
        double destinationY = r.nextGaussian(40.03375, 0.0105619);
        return CoordUtils.createCoord(destinationX, destinationY);
    }

    private double getRandomTime(Double currentTime, Random r, Double minGap, Double maxGap) {
        // Code to generate a random start time within the specified time window
        return (currentTime + r.nextDouble(minGap, maxGap));
    }

    private boolean shouldReturnHome(Random r, int consecutiveTrips) {
        // Determine the probability of returning home based on the number of consecutive trips done
        Double goHomeProb = r.nextDouble(0.0, 1.0);
        if (consecutiveTrips <= 1) {
            return goHomeProb < 0.4;
        } else if (consecutiveTrips <= 2) {
            return goHomeProb < 0.6;
        } else {
            return goHomeProb < 0.8;
        }
    }

    private void makeMandatoryTour(Plan plan, Random r) {
        // Works north or south
        Coord nbWorkLoc = CoordUtils.createCoord(-111.6833027, 40.1037746);
        Coord sbWorkLoc = CoordUtils.createCoord(-111.7934400, 39.9599421);
        Coord workLocation;
        if(r.nextDouble(0.0, 1.0) < 0.05) {
            workLocation = sbWorkLoc;
        } else {
            workLocation = nbWorkLoc;
        }

        Double startTime = getRandomTime(3600*7.0, r, 0.0, 3600*2.0);
        Double endTime = getRandomTime(3600*16.0, r, 0.0, 3600*2.0);

        // make mandatory activity (including time)
        Activity workActivity = pf.createActivityFromCoord("Mandatory", workLocation);
        workActivity.setStartTime(startTime);
        workActivity.setEndTime(endTime);
        plan.addActivity(workActivity);

        Leg leg = pf.createLeg("car");
        plan.addLeg(leg);

        // make a discretionary activity on the way home sometimes
        if(r.nextDouble() < 0.5){
            startTime = getRandomTime(endTime, r, 3600*0.5, 3600*1.0);
            endTime = getRandomTime(startTime, r, 3600*0.5, 3600*3.0);

            Activity extraActivity = pf.createActivityFromCoord("Discretionary", workLocation);
            extraActivity.setStartTime(startTime);
            extraActivity.setEndTime(endTime);
            plan.addActivity(extraActivity);

            Leg legDisc = pf.createLeg("car");
            plan.addLeg(legDisc);
        }


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
