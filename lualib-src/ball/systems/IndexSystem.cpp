#include "IndexSystem.h"

#include <EntitasPP/Group.h>
#include <EntitasPP/Matcher.h>
#include <components\IndexComponent.h>


namespace Chestnut {
	namespace Ball {




		auto IndexSystem::SetPool(RefCountedPtr<EntitasPP::Pool> pool) -> void {
			this->_pool = pool;
		}

		auto IndexSystem::Initialize() ->void {}

		auto IndexSystem::FixedExecute() -> void {}

		auto IndexSystem::OnEntityCreated(EntitasPP::Pool* pool, EntitasPP::EntityPtr entity) -> void {
			/*int index = entity->Get<IndexComponent>()->index;
			entitas.emplace(std::make_pair<int, EntitasPP::EntityPtr>(index, entity));*/
		}

		auto IndexSystem::FindEntity(int index) -> EntitasPP::EntityPtr {
			return _entitas[index];
		}

	}
}



