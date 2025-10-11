// SampleDataProvider.swift
import Foundation
import SwiftData

@MainActor
final class SampleDataProvider {
    
    static func createSampleData(in modelContext: ModelContext) {
        // Check if sample data already exists
        let fetchDescriptor = FetchDescriptor<Card>()
        if let existingCards = try? modelContext.fetch(fetchDescriptor), !existingCards.isEmpty {
            return // Sample data already exists
        }
        
        // Project cards
        let dragonProject = Card(
            kind: .projects,
            name: "The Dragon Chronicles",
            subtitle: "Epic fantasy series",
            detailedText: """
            # The Dragon Chronicles
            
            An epic fantasy series following the last dragonrider, Lyra, as she discovers her ancient heritage and battles against the Shadow Lord who threatens to plunge the world into eternal darkness.
            
            ## Key Themes
            - Coming of age in a magical world
            - The bond between human and dragon
            - Ancient prophecies and their interpretations
            - Light vs darkness, good vs evil
            
            ## Target Audience
            Young adult fantasy readers who enjoy complex world-building and character development.
            """,
            author: "J.K. Author"
        )
        
        let mysteryProject = Card(
            kind: .projects,
            name: "Midnight in the Library",
            subtitle: "A cozy mystery novel",
            detailedText: """
            # Midnight in the Library
            
            When librarian Sarah discovers a rare manuscript hidden in the old section, she uncovers a century-old mystery involving missing persons and ancient secrets. But someone else wants that manuscript, and they'll do anything to get it.
            
            ## Plot Points
            - Discovery of the mysterious manuscript
            - Research into historical disappearances
            - Cat-and-mouse game with the antagonist
            - Final confrontation in the library at midnight
            
            ## Setting
            Small college town with a historic library built in 1890.
            """,
            author: "Mystery Writer"
        )
        
        // Character cards
        let lyra = Card(
            kind: .characters,
            name: "Lyra Dragonheart",
            subtitle: "Protagonist, last dragonrider",
            detailedText: """
            # Lyra Dragonheart
            
            **Age**: 17  
            **Species**: Human/Dragon-touched  
            **Occupation**: Apprentice blacksmith turned dragonrider
            
            ## Description
            Lyra has silver-streaked auburn hair that seems to shimmer with an inner light. Her eyes change color based on her emotions - green when calm, gold when angry, and silver when using dragon magic. She bears the mark of the dragon on her left shoulder, a birthmark that glows when she's near her dragon companion.
            
            ## Personality
            - Stubborn and determined
            - Quick to defend the innocent
            - Struggles with self-doubt despite her power
            - Has a dry sense of humor
            
            ## Background
            Raised by her blacksmith uncle after her parents died in a dragon attack (which she later learns was orchestrated by the Shadow Lord). She discovers her dragon heritage when she accidentally calls an ancient dragon from its centuries-long slumber.
            
            ## Arc
            From self-doubting apprentice to confident dragonrider who saves the world.
            """,
            author: "J.K. Author"
        )
        
        let ember = Card(
            kind: .characters,
            name: "Ember",
            subtitle: "Ancient red dragon, Lyra's companion",
            detailedText: """
            # Ember
            
            **Age**: Over 1000 years old  
            **Species**: Ancient Red Dragon  
            **Size**: Massive (100-foot wingspan when fully grown)
            
            ## Description
            Ember is a magnificent red dragon with scales that appear to contain actual fire. Her eyes are like molten gold, and smoke occasionally curls from her nostrils. When she was awakened by Lyra, she was only the size of a horse, but she grows throughout the series.
            
            ## Personality
            - Ancient wisdom combined with fierce protectiveness
            - Sardonic sense of humor
            - Initially skeptical of humans but grows to love Lyra
            - Proud of her dragon heritage
            
            ## Abilities
            - Firebreath that can melt stone
            - Flight at incredible speeds
            - Telepathic communication with dragonriders
            - Ancient magic knowledge
            
            ## Background
            Last of the great dragons, she went into hibernation after the Dragon Wars ended 500 years ago. She had bonded with Lyra's ancestor and waited centuries for another of her bloodline to awaken her.
            """,
            author: "J.K. Author"
        )
        
        // World building cards
        let dragonia = Card(
            kind: .worlds,
            name: "Dragonia",
            subtitle: "The realm where dragons once flew free",
            detailedText: """
            # The World of Dragonia
            
            A fantasy realm where magic once flowed freely and dragons soared through crystal-blue skies. After the Dragon Wars, magic became restricted and dragons disappeared, leaving behind only legends and the occasional dragon-touched human.
            
            ## Geography
            - **The Sunward Peaks**: Mountain range where the last dragon lairs are hidden
            - **Shadowmere**: Dark swamplands controlled by the Shadow Lord
            - **The Golden Plains**: Fertile farmlands where most humans live
            - **The Whispering Woods**: Ancient forest where elves once dwelt
            
            ## Magic System
            Magic flows through ley lines that crisscross the world. Dragon magic is the most powerful, followed by elemental magic used by human mages. The Shadow Lord seeks to corrupt the ley lines to increase his power.
            
            ## History
            - **Age of Dragons**: 2000 years of peace with dragons and humans coexisting
            - **The Dragon Wars**: 500-year conflict that ended with most dragons vanishing
            - **The Age of Forgetting**: Current era where dragons are considered myths
            
            ## Current Situation
            The Shadow Lord grows stronger each year, and strange creatures emerge from Shadowmere. Ancient prophecies speak of the return of the dragonriders.
            """,
            author: "J.K. Author"
        )
        
        // Source material
        let dragonLore = Card(
            kind: .sources,
            name: "Ancient Dragon Lore Compendium",
            subtitle: "Research source for dragon mythology",
            detailedText: """
            # Ancient Dragon Lore Compendium
            
            A comprehensive collection of dragon myths, legends, and historical accounts from various cultures around the world. This source provides the foundation for the magical system and dragon biology in The Dragon Chronicles.
            
            ## Key Insights
            - Dragon-human bonds in ancient Celtic mythology
            - Chinese dragon wisdom and longevity
            - European dragon treasure hoarding behaviors  
            - Native American dragon spirits and their connection to nature
            
            ## Relevant Quotes
            "The bond between dragon and rider transcends mortality itself, for in that union, both achieve a form of immortality that neither could reach alone." - Celtic Dragon Tales, Chapter 3
            
            ## Application
            Used to develop the magical bond system between Lyra and Ember, as well as the ancient history of Dragonia.
            """,
            author: "Various mythological sources"
        )
        
        // Insert all sample cards
        let sampleCards = [dragonProject, mysteryProject, lyra, ember, dragonia, dragonLore]
        
        for card in sampleCards {
            modelContext.insert(card)
        }
        
        try? modelContext.save()
    }
}