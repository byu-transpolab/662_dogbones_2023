package org.matsim.project;

import org.matsim.api.core.v01.Scenario;
import org.matsim.api.core.v01.population.PopulationFactory;
import org.matsim.core.config.Config;
import org.matsim.core.config.ConfigUtils;
import org.matsim.core.population.io.PopulationWriter;
import org.matsim.core.scenario.ScenarioUtils;
import org.matsim.core.utils.geometry.CoordinateTransformation;
import org.matsim.core.utils.geometry.transformations.TransformationFactory;

import java.util.Random;

public class CreatePaysonPop {
    static Random random = new Random(43);
    static Scenario scenario = null;
    static PopulationFactory pf = null;
    static CoordinateTransformation ct = null;

    static void setupScenario(String crs){
        Config config = ConfigUtils.createConfig();
        scenario = ScenarioUtils.createScenario(config);
        pf = scenario.getPopulation().getFactory();
        scenario.getConfig().global().setCoordinateSystem(crs);

        ct = TransformationFactory.getCoordinateTransformation(
                TransformationFactory.WGS84,
                crs
        );

    }

    static void createNPeople (Integer n){
        for(Integer i = 0; i < n; i++) new PaysonPerson(i, random, scenario, pf, ct);
    }

    static void writePopulation(String filename) {
        PopulationWriter writer = new PopulationWriter(scenario.getPopulation());
        writer.write(filename);
    }

    public static void main(String[] args) {
        Integer n = Integer.valueOf(args[0]);
        String populationFile = args[1];
        setupScenario("EPSG:26912");

        createNPeople(n);
        System.out.println("Made " + n + " persons");

        writePopulation(populationFile);
        System.out.println("Wrote population at " + populationFile);
    }

}

