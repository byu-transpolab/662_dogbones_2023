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
        Person p = pf.createPerson(Id.createPersonId(id));
        p.getAttributes().putAttribute("age", age);
        p.getAttributes().putAttribute("gender", gender);
        p.getAttributes().putAttribute("worker", worker);
        makePlans(p, r);
        sc.getPopulation().addPerson(p);
    }

    void makePlans(Person p, Random r){
        Plan plan = pf.createPlan();
        Double patternProb = r.nextDouble(0.0, 1.0);
        Double homeX = r.nextGaussian(0,1);
        Double homeY = r.nextGaussian(0, 1);
        Coord homeLocation = CoordUtils.createCoord(homeX, homeY);

        // everyone starts at home
        Activity homeStart = pf.createActivityFromCoord("Home", homeLocation);

       // if home pattern, then they never leave
        homeStart.setEndTime(6 * 3600);
        plan.addActivity(homeStart);

        Leg leg = pf.createLeg("car");
        plan.addLeg(leg);

       // if work pattern, then travel to I-15 NB and return later


        Activity homeEnd = pf.createActivityFromCoord("Home", homeLocation);
        homeEnd.setEndTime(24*3600);
        plan.addActivity(homeEnd);


       // if discretionary, then maybe travel?
        p.addPlan(plan);
        p.setSelectedPlan(plan);
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
